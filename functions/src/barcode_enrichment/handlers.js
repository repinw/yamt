const logger = require("firebase-functions/logger");
const { HttpsError } = require("firebase-functions/v2/https");
const {
  FUNCTION_REGION,
  JOB_COLLECTION,
  WORKER_MAX_INSTANCES,
  MAX_JOB_RETRIES,
  KEYWORD_ALIAS_MIN_SCORE,
  MODEL_NAME,
  MODEL_LOCATION,
} = require("./runtime");
const { resolveRequestUid } = require("./auth");
const {
  readString,
  nowIso,
  computeFoodFingerprint,
  normalizeEnqueueItems,
  buildKeywords,
  buildLookupKeywords,
  ensureCandidatesContainBarcode,
  composeJobId,
  inventoryItemRef,
  normalizeJob,
  extractErrorMessage,
  extractErrorDetails,
  isResourceExhaustedError,
} = require("./helpers");
const {
  resolveFromGlobalCatalog,
  touchGlobalResolution,
  upsertGlobalResolution,
} = require("./global_catalog");
const {
  lockQueuedJob,
  markJobDone,
  markJobNoResult,
  markJobFailed,
  markJobResourceExhausted,
} = require("./jobs");
const {
  resolveAndPersistItem,
  persistItemResolved,
} = require("./item_resolution");
const { db } = require("./runtime");

const resolveInventoryItemBarcodeOptions = {
  region: FUNCTION_REGION,
  timeoutSeconds: 120,
  memory: "512MiB",
  enforceAppCheck: false,
};

const enqueueInventoryBarcodeJobsOptions = {
  region: FUNCTION_REGION,
  timeoutSeconds: 120,
  memory: "256MiB",
  enforceAppCheck: false,
};

const onBarcodeEnrichmentJobWrittenOptions = {
  document: `${JOB_COLLECTION}/{jobId}`,
  region: FUNCTION_REGION,
  timeoutSeconds: 120,
  memory: "512MiB",
  maxInstances: WORKER_MAX_INSTANCES,
  retry: false,
};

async function resolveInventoryItemBarcodeHandler(request) {
  const uid = resolveRequestUid(request, "resolveInventoryItemBarcode");

  const itemId = readString(request.data?.itemId);
  if (!itemId) {
    return {
      success: false,
      found: false,
      barcode: null,
      candidates: [],
      error: "missing_item_id",
    };
  }

  try {
    const itemRef = inventoryItemRef(uid, itemId);
    const itemSnapshot = await itemRef.get();
    if (!itemSnapshot.exists) {
      return {
        success: false,
        found: false,
        barcode: null,
        candidates: [],
        error: "item_not_found",
      };
    }

    const itemData = itemSnapshot.data() ?? {};
    const itemName = readString(request.data?.itemName) ??
      readString(itemData.name);
    if (!itemName) {
      return {
        success: false,
        found: false,
        barcode: null,
        candidates: [],
        error: "missing_item_name",
      };
    }

    const brand = readString(request.data?.brand) ??
      readString(itemData.brand);
    const storeName = readString(request.data?.storeName) ??
      readString(itemData.storeName);
    const weight = readString(request.data?.weight) ??
      readString(itemData.weight);
    const fingerprint = readString(request.data?.fingerprint) ??
      readString(itemData.foodFingerprint) ??
      computeFoodFingerprint({ name: itemName, brand });
    const trigger = readString(request.data?.trigger) ?? "manual_search";

    logger.info("Resolving inventory item barcode.", {
      uid,
      itemId,
      fingerprint,
      trigger,
      model: MODEL_NAME,
      location: MODEL_LOCATION,
      sdk: "@google/genai",
    });

    const outcome = await resolveAndPersistItem({
      uid,
      itemId,
      itemName,
      brand,
      storeName,
      weight,
      fingerprint,
      trigger,
      itemRef,
    });

    return {
      success: true,
      found: outcome.found,
      barcode: outcome.barcode,
      candidates: outcome.candidates,
      source: outcome.source,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("resolveInventoryItemBarcode failed.", {
      uid,
      itemId,
      error: extractErrorMessage(error),
      details: extractErrorDetails(error),
    });
    return {
      success: false,
      found: false,
      barcode: null,
      candidates: [],
      error: extractErrorMessage(error),
    };
  }
}

async function enqueueInventoryBarcodeJobsHandler(request) {
  const uid = resolveRequestUid(request, "enqueueInventoryBarcodeJobs");

  const trigger = readString(request.data?.trigger) ?? "receipt_upload";
  const rawItems = Array.isArray(request.data?.items) ?
    request.data.items :
    [];
  const items = normalizeEnqueueItems(rawItems);
  if (items.length === 0) {
    return {
      success: false,
      queuedCount: 0,
      jobIds: [],
      error: "missing_items",
    };
  }

  const now = nowIso();
  const queueBatch = db.batch();
  const jobIds = [];
  let resolvedCount = 0;

  for (const item of items) {
    const searchKeywords = buildKeywords({
      itemName: item.itemName,
      brand: item.brand,
      storeName: item.storeName,
      weight: item.weight,
      fingerprint: item.fingerprint,
    });
    const lookupKeywords = buildLookupKeywords({
      itemName: item.itemName,
      brand: item.brand,
      weight: item.weight,
    });
    const globalMatch = await resolveFromGlobalCatalog({
      fingerprint: item.fingerprint,
      itemName: item.itemName,
      brand: item.brand,
      weight: item.weight,
      lookupKeywords,
    });
    if (globalMatch?.barcode) {
      const itemRef = inventoryItemRef(uid, item.itemId);
      const candidates = ensureCandidatesContainBarcode(
        globalMatch.barcodeCandidates,
        globalMatch.barcode,
      );
      await persistItemResolved({
        itemRef,
        fingerprint: item.fingerprint,
        requestedAt: now,
        barcode: globalMatch.barcode,
        candidates,
        searchKeywords,
      });
      await touchGlobalResolution(globalMatch.matchedFingerprint);
      if (
        globalMatch.matchedFingerprint !== item.fingerprint &&
        globalMatch.matchType === "keyword" &&
        globalMatch.score >= KEYWORD_ALIAS_MIN_SCORE
      ) {
        await upsertGlobalResolution({
          fingerprint: item.fingerprint,
          barcode: globalMatch.barcode,
          candidates,
          itemName: item.itemName,
          brand: item.brand,
          storeName: item.storeName,
          weight: item.weight,
          source: "global_keyword_match",
          keywordMatchScore: globalMatch.score,
          uid,
        });
      }
      resolvedCount += 1;
      continue;
    }

    const jobId = composeJobId(uid, item.itemId);
    const jobRef = db.collection(JOB_COLLECTION).doc(jobId);
    queueBatch.set(
      jobRef,
      {
        jobId,
        uid,
        itemId: item.itemId,
        itemName: item.itemName,
        brand: item.brand,
        storeName: item.storeName,
        weight: item.weight,
        fingerprint: item.fingerprint,
        keywords: searchKeywords,
        trigger,
        status: "queued",
        attempts: 0,
        maxRetries: MAX_JOB_RETRIES,
        queuedAt: now,
        updatedAt: now,
        startedAt: null,
        completedAt: null,
        lastError: null,
        found: null,
        barcode: null,
        candidates: [],
      },
      { merge: true },
    );
    jobIds.push(jobId);
  }

  if (jobIds.length > 0) {
    await queueBatch.commit();
  }
  logger.info("Enqueued inventory barcode jobs.", {
    uid,
    trigger,
    queuedCount: jobIds.length,
    resolvedCount,
  });

  return {
    success: true,
    queuedCount: jobIds.length,
    resolvedCount,
    jobIds,
  };
}

async function onBarcodeEnrichmentJobWrittenHandler(event) {
  const after = event.data?.after;
  if (!after?.exists) {
    return;
  }

  const lock = await lockQueuedJob(after.ref);
  if (!lock.shouldProcess) {
    return;
  }

  const snapshot = await after.ref.get();
  if (!snapshot.exists) {
    return;
  }
  const job = normalizeJob(snapshot.data());
  if (!job) {
    await markJobFailed({
      jobRef: after.ref,
      attempts: lock.attempts,
      error: "invalid_job_payload",
    });
    return;
  }

  try {
    const outcome = await resolveAndPersistItem({
      uid: job.uid,
      itemId: job.itemId,
      itemName: job.itemName,
      brand: job.brand,
      storeName: job.storeName,
      weight: job.weight,
      fingerprint: job.fingerprint,
      trigger: job.trigger,
    });
    if (outcome.found) {
      await markJobDone({
        jobRef: after.ref,
        attempts: lock.attempts,
        fingerprint: job.fingerprint,
        found: true,
        barcode: outcome.barcode,
        candidates: outcome.candidates,
        source: outcome.source,
      });
    } else {
      await markJobNoResult({
        jobRef: after.ref,
        attempts: lock.attempts,
        fingerprint: job.fingerprint,
        candidates: outcome.candidates,
        source: outcome.source,
      });
    }
  } catch (error) {
    if (isResourceExhaustedError(error)) {
      await markJobResourceExhausted({
        jobRef: after.ref,
        attempts: lock.attempts,
        error: extractErrorMessage(error),
      });
      logger.warn("Barcode enrichment job throttled (resource exhausted).", {
        jobId: after.id,
        attempts: lock.attempts,
        error: extractErrorMessage(error),
        details: extractErrorDetails(error),
      });
      return;
    }

    await markJobFailed({
      jobRef: after.ref,
      attempts: lock.attempts,
      error: extractErrorMessage(error),
    });
    logger.error("Barcode enrichment job failed.", {
      jobId: after.id,
      attempts: lock.attempts,
      error: extractErrorMessage(error),
      details: extractErrorDetails(error),
    });
  }
}

module.exports = {
  resolveInventoryItemBarcodeOptions,
  enqueueInventoryBarcodeJobsOptions,
  onBarcodeEnrichmentJobWrittenOptions,
  resolveInventoryItemBarcodeHandler,
  enqueueInventoryBarcodeJobsHandler,
  onBarcodeEnrichmentJobWrittenHandler,
};
