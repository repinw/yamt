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
  db,
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

function createBarcodeHandlers({
  functionRegion = FUNCTION_REGION,
  jobCollection = JOB_COLLECTION,
  workerMaxInstances = WORKER_MAX_INSTANCES,
  maxJobRetries = MAX_JOB_RETRIES,
  keywordAliasMinScore = KEYWORD_ALIAS_MIN_SCORE,
  modelName = MODEL_NAME,
  modelLocation = MODEL_LOCATION,
  dbClient = db,
  loggerValue = logger,
  httpsErrorClass = HttpsError,
  resolveRequestUidValue = resolveRequestUid,
  readStringValue = readString,
  nowIsoValue = nowIso,
  computeFoodFingerprintValue = computeFoodFingerprint,
  normalizeEnqueueItemsValue = normalizeEnqueueItems,
  buildKeywordsValue = buildKeywords,
  buildLookupKeywordsValue = buildLookupKeywords,
  ensureCandidatesContainBarcodeValue = ensureCandidatesContainBarcode,
  composeJobIdValue = composeJobId,
  inventoryItemRefValue = inventoryItemRef,
  normalizeJobValue = normalizeJob,
  extractErrorMessageValue = extractErrorMessage,
  extractErrorDetailsValue = extractErrorDetails,
  isResourceExhaustedErrorValue = isResourceExhaustedError,
  resolveFromGlobalCatalogValue = resolveFromGlobalCatalog,
  touchGlobalResolutionValue = touchGlobalResolution,
  upsertGlobalResolutionValue = upsertGlobalResolution,
  lockQueuedJobValue = lockQueuedJob,
  markJobDoneValue = markJobDone,
  markJobNoResultValue = markJobNoResult,
  markJobFailedValue = markJobFailed,
  markJobResourceExhaustedValue = markJobResourceExhausted,
  resolveAndPersistItemValue = resolveAndPersistItem,
  persistItemResolvedValue = persistItemResolved,
} = {}) {
  const resolveInventoryItemBarcodeOptions = {
    region: functionRegion,
    timeoutSeconds: 120,
    memory: "512MiB",
    enforceAppCheck: false,
  };

  const enqueueInventoryBarcodeJobsOptions = {
    region: functionRegion,
    timeoutSeconds: 120,
    memory: "256MiB",
    enforceAppCheck: false,
  };

  const onBarcodeEnrichmentJobWrittenOptions = {
    document: `${jobCollection}/{jobId}`,
    region: functionRegion,
    timeoutSeconds: 120,
    memory: "512MiB",
    maxInstances: workerMaxInstances,
    retry: false,
  };

  async function resolveInventoryItemBarcodeHandler(request) {
    const uid = resolveRequestUidValue(request, "resolveInventoryItemBarcode");

    const itemId = readStringValue(request.data?.itemId);
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
      const itemRef = inventoryItemRefValue(uid, itemId);
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
      const itemName = readStringValue(request.data?.itemName) ??
        readStringValue(itemData.name);
      if (!itemName) {
        return {
          success: false,
          found: false,
          barcode: null,
          candidates: [],
          error: "missing_item_name",
        };
      }

      const brand = readStringValue(request.data?.brand) ??
        readStringValue(itemData.brand);
      const storeName = readStringValue(request.data?.storeName) ??
        readStringValue(itemData.storeName);
      const weight = readStringValue(request.data?.weight) ??
        readStringValue(itemData.weight);
      const fingerprint = readStringValue(request.data?.fingerprint) ??
        readStringValue(itemData.foodFingerprint) ??
        computeFoodFingerprintValue({ name: itemName, brand });
      const trigger = readStringValue(request.data?.trigger) ??
        "manual_search";

      loggerValue.info("Resolving inventory item barcode.", {
        uid,
        itemId,
        fingerprint,
        trigger,
        model: modelName,
        location: modelLocation,
        sdk: "@google/genai",
      });

      const outcome = await resolveAndPersistItemValue({
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
      if (error instanceof httpsErrorClass) {
        throw error;
      }
      loggerValue.error("resolveInventoryItemBarcode failed.", {
        uid,
        itemId,
        error: extractErrorMessageValue(error),
        details: extractErrorDetailsValue(error),
      });
      return {
        success: false,
        found: false,
        barcode: null,
        candidates: [],
        error: extractErrorMessageValue(error),
      };
    }
  }

  async function enqueueInventoryBarcodeJobsHandler(request) {
    const uid = resolveRequestUidValue(request, "enqueueInventoryBarcodeJobs");

    const trigger = readStringValue(request.data?.trigger) ?? "receipt_upload";
    const rawItems = Array.isArray(request.data?.items) ?
      request.data.items :
      [];
    const items = normalizeEnqueueItemsValue(rawItems);
    if (items.length === 0) {
      return {
        success: false,
        queuedCount: 0,
        jobIds: [],
        error: "missing_items",
      };
    }

    const now = nowIsoValue();
    const queueBatch = dbClient.batch();
    const jobIds = [];
    let resolvedCount = 0;

    const preparedItems = items.map((item) => {
      const searchKeywords = buildKeywordsValue({
        itemName: item.itemName,
        brand: item.brand,
        storeName: item.storeName,
        weight: item.weight,
        fingerprint: item.fingerprint,
      });
      const lookupKeywords = buildLookupKeywordsValue({
        itemName: item.itemName,
        brand: item.brand,
        weight: item.weight,
      });
      return {
        item,
        searchKeywords,
        lookupKeywords,
      };
    });

    const globalMatches = await Promise.all(preparedItems.map(
      async (prepared) => {
        const globalMatch = await resolveFromGlobalCatalogValue({
          fingerprint: prepared.item.fingerprint,
          itemName: prepared.item.itemName,
          brand: prepared.item.brand,
          weight: prepared.item.weight,
          lookupKeywords: prepared.lookupKeywords,
        });
        return globalMatch;
      },
    ));

    for (let index = 0; index < preparedItems.length; index += 1) {
      const prepared = preparedItems[index];
      const item = prepared.item;
      const searchKeywords = prepared.searchKeywords;
      const globalMatch = globalMatches[index];

      if (globalMatch?.barcode) {
        const itemRef = inventoryItemRefValue(uid, item.itemId);
        const candidates = ensureCandidatesContainBarcodeValue(
          globalMatch.barcodeCandidates,
          globalMatch.barcode,
        );
        await persistItemResolvedValue({
          itemRef,
          fingerprint: item.fingerprint,
          requestedAt: now,
          barcode: globalMatch.barcode,
          candidates,
          searchKeywords,
        });
        await touchGlobalResolutionValue(globalMatch.matchedFingerprint);
        if (
          globalMatch.matchedFingerprint !== item.fingerprint &&
          globalMatch.matchType === "keyword" &&
          globalMatch.score >= keywordAliasMinScore
        ) {
          await upsertGlobalResolutionValue({
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

      const jobId = composeJobIdValue(uid, item.itemId);
      const jobRef = dbClient.collection(jobCollection).doc(jobId);
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
          maxRetries: maxJobRetries,
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
    loggerValue.info("Enqueued inventory barcode jobs.", {
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

    const lock = await lockQueuedJobValue(after.ref);
    if (!lock.shouldProcess) {
      return;
    }

    const snapshot = await after.ref.get();
    if (!snapshot.exists) {
      return;
    }
    const job = normalizeJobValue(snapshot.data());
    if (!job) {
      await markJobFailedValue({
        jobRef: after.ref,
        attempts: lock.attempts,
        error: "invalid_job_payload",
      });
      return;
    }

    try {
      const outcome = await resolveAndPersistItemValue({
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
        await markJobDoneValue({
          jobRef: after.ref,
          attempts: lock.attempts,
          fingerprint: job.fingerprint,
          found: true,
          barcode: outcome.barcode,
          candidates: outcome.candidates,
          source: outcome.source,
        });
      } else {
        await markJobNoResultValue({
          jobRef: after.ref,
          attempts: lock.attempts,
          fingerprint: job.fingerprint,
          candidates: outcome.candidates,
          source: outcome.source,
        });
      }
    } catch (error) {
      if (isResourceExhaustedErrorValue(error)) {
        await markJobResourceExhaustedValue({
          jobRef: after.ref,
          attempts: lock.attempts,
          error: extractErrorMessageValue(error),
        });
        loggerValue.warn(
          "Barcode enrichment job throttled (resource exhausted).",
          {
            jobId: after.id,
            attempts: lock.attempts,
            error: extractErrorMessageValue(error),
            details: extractErrorDetailsValue(error),
          },
        );
        return;
      }

      await markJobFailedValue({
        jobRef: after.ref,
        attempts: lock.attempts,
        error: extractErrorMessageValue(error),
      });
      loggerValue.error("Barcode enrichment job failed.", {
        jobId: after.id,
        attempts: lock.attempts,
        error: extractErrorMessageValue(error),
        details: extractErrorDetailsValue(error),
      });
    }
  }

  return {
    resolveInventoryItemBarcodeOptions,
    enqueueInventoryBarcodeJobsOptions,
    onBarcodeEnrichmentJobWrittenOptions,
    resolveInventoryItemBarcodeHandler,
    enqueueInventoryBarcodeJobsHandler,
    onBarcodeEnrichmentJobWrittenHandler,
  };
}

const defaultBarcodeHandlers = createBarcodeHandlers();

module.exports = {
  createBarcodeHandlers,
  ...defaultBarcodeHandlers,
};
