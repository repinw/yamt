const logger = require("firebase-functions/logger");
const { HttpsError } = require("firebase-functions/v2/https");
const {
  FUNCTION_REGION,
  JOB_COLLECTION,
  WORKER_MAX_INSTANCES,
  MAX_JOB_RETRIES,
  VERTEX_ENRICHMENT_MIN_INTERVAL_MS,
  VERTEX_RESOURCE_EXHAUSTED_COOLDOWN_MS,
  KEYWORD_ALIAS_MIN_SCORE,
  MODEL_NAME,
  MODEL_LOCATION,
  FieldValue,
  db,
} = require("./runtime");
const { resolveRequestUid } = require("./auth");
const {
  readString,
  readPositiveIntFromEnv,
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
const {
  readTimestampMs,
  acquireRateLimitSlot: acquireRateLimitSlotShared,
  applyRateLimitCooldown: applyRateLimitCooldownShared,
  waitUntil,
} = require("../shared/rate_limit");

const AI_RATE_LIMIT_COLLECTION = "ai_rate_limits";
const AI_BARCODE_ENRICHMENT_GATE_DOC = "barcode_enrichment";
const MAX_CALLABLE_RATE_LIMIT_WAIT_MS = 70 * 1000;
const JOB_RECOVERY_BATCH_SIZE = readPositiveIntFromEnv(
  "BARCODE_JOB_RECOVERY_BATCH_SIZE",
  100,
);
const RUNNING_JOB_STALE_MS = readPositiveIntFromEnv(
  "BARCODE_JOB_RUNNING_STALE_MS",
  10 * 60 * 1000,
);

function createBarcodeHandlers({
  functionRegion = FUNCTION_REGION,
  jobCollection = JOB_COLLECTION,
  workerMaxInstances = WORKER_MAX_INSTANCES,
  maxJobRetries = MAX_JOB_RETRIES,
  vertexRateLimitCollection = AI_RATE_LIMIT_COLLECTION,
  vertexRateLimitDocId = AI_BARCODE_ENRICHMENT_GATE_DOC,
  vertexMinIntervalMs = VERTEX_ENRICHMENT_MIN_INTERVAL_MS,
  maxCallableRateLimitWaitMs = MAX_CALLABLE_RATE_LIMIT_WAIT_MS,
  vertexResourceExhaustedCooldownMs = VERTEX_RESOURCE_EXHAUSTED_COOLDOWN_MS,
  jobRecoveryBatchSize = JOB_RECOVERY_BATCH_SIZE,
  runningJobStaleMs = RUNNING_JOB_STALE_MS,
  keywordAliasMinScore = KEYWORD_ALIAS_MIN_SCORE,
  modelName = MODEL_NAME,
  modelLocation = MODEL_LOCATION,
  dbClient = db,
  loggerValue = logger,
  httpsErrorClass = HttpsError,
  resolveRequestUidValue = resolveRequestUid,
  readStringValue = readString,
  nowIsoValue = nowIso,
  nowMsValue = () => Date.now(),
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
  acquireRateLimitSlotValue = acquireRateLimitSlot,
  applyRateLimitCooldownValue = applyRateLimitCooldown,
  waitUntilValue = waitUntil,
  recoverBackoffWaitJobsValue = recoverBackoffWaitJobs,
  recoverStaleRunningJobsValue = recoverStaleRunningJobs,
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

  const recoverBarcodeEnrichmentJobsOptions = {
    region: functionRegion,
    schedule: "every 1 minutes",
    timeZone: "Etc/UTC",
    timeoutSeconds: 120,
    memory: "256MiB",
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
        uncertain: false,
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
          uncertain: false,
          error: "item_not_found",
        };
      }

      const itemData = itemSnapshot.data() ?? {};
      const productSnapshot = itemData.product_snapshot ?? {};
      const itemName = readStringValue(request.data?.itemName) ??
        readStringValue(productSnapshot.name);
      if (!itemName) {
        return {
          success: false,
          found: false,
          barcode: null,
          candidates: [],
          uncertain: false,
          error: "missing_item_name",
        };
      }

      const brand = readStringValue(request.data?.brand) ??
        readStringValue(productSnapshot.brand);
      const storeName = readStringValue(request.data?.storeName) ??
        readStringValue(itemData.store_name);
      const weight = readStringValue(request.data?.weight) ??
        readStringValue(itemData.weight);
      const fingerprint = readStringValue(request.data?.fingerprint) ??
        readStringValue(productSnapshot.food_fingerprint) ??
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

      const scheduledAtMs = await acquireRateLimitSlotValue({
        dbClient,
        collection: vertexRateLimitCollection,
        documentId: vertexRateLimitDocId,
        minIntervalMs: vertexMinIntervalMs,
        maxWaitMs: maxCallableRateLimitWaitMs,
        nowMs: nowMsValue(),
      });
      await waitUntilValue(scheduledAtMs, nowMsValue);

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
        uncertain: Boolean(outcome.uncertain),
        source: outcome.source,
      };
    } catch (error) {
      if (isRateLimitQueueFullError(error)) {
        const waitMs = toNonNegativeInt(error.waitMs);
        const retryAfterSeconds = Math.max(1, Math.ceil(waitMs / 1000));
        loggerValue.warn("Barcode callable throttled due to queue depth.", {
          uid,
          itemId,
          waitMs,
          retryAfterSeconds,
          maxCallableRateLimitWaitMs,
        });
        throw new httpsErrorClass(
          "resource-exhausted",
          "barcode_lookup_queue_busy",
          {
            retryAfterSeconds,
          },
        );
      }
      if (error instanceof httpsErrorClass) {
        throw error;
      }
      if (isResourceExhaustedErrorValue(error)) {
        await applyRateLimitCooldownValue({
          dbClient,
          collection: vertexRateLimitCollection,
          documentId: vertexRateLimitDocId,
          cooldownMs: vertexResourceExhaustedCooldownMs,
          nowMs: nowMsValue(),
        });
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
        uncertain: false,
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
        const barcodeLookupUncertain = Boolean(
          globalMatch.barcodeLookupUncertain,
        );
        await persistItemResolvedValue({
          itemRef,
          fingerprint: item.fingerprint,
          requestedAt: now,
          barcode: globalMatch.barcode,
          candidates,
          barcodeLookupUncertain,
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
            barcodeLookupUncertain,
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
          resourceExhaustedCount: 0,
          maxRetries: maxJobRetries,
          queuedAt: now,
          updatedAt: now,
          startedAt: null,
          nextAttemptAt: null,
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
      const scheduledAtMs = await acquireRateLimitSlotValue({
        dbClient,
        collection: vertexRateLimitCollection,
        documentId: vertexRateLimitDocId,
        minIntervalMs: vertexMinIntervalMs,
        nowMs: nowMsValue(),
      });
      await waitUntilValue(scheduledAtMs, nowMsValue);

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
          barcodeLookupUncertain: outcome.uncertain,
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
      const isResourceExhausted = isResourceExhaustedErrorValue(error);
      const isRateLimitBackoffError = isRateLimitQueueFullError(error) ||
        isRateLimitWaitTimeoutError(error);

      if (isResourceExhausted || isRateLimitBackoffError) {
        if (isResourceExhausted) {
          await applyRateLimitCooldownValue({
            dbClient,
            collection: vertexRateLimitCollection,
            documentId: vertexRateLimitDocId,
            cooldownMs: vertexResourceExhaustedCooldownMs,
            nowMs: nowMsValue(),
          });
        }
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
            reason: isResourceExhausted ?
              "resource_exhausted" :
              "rate_limit_backoff",
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

  async function recoverBarcodeEnrichmentJobsHandler() {
    const nowMs = nowMsValue();
    const nowIsoTimestamp = new Date(nowMs).toISOString();
    const staleBeforeMs = nowMs - Math.max(1, runningJobStaleMs);

    const recoveredBackoffWaitCount = await recoverBackoffWaitJobsValue({
      dbClient,
      jobCollection,
      nowIsoTimestamp,
      nowMs,
      batchSize: jobRecoveryBatchSize,
    });
    const recoveredRunningCount = await recoverStaleRunningJobsValue({
      dbClient,
      jobCollection,
      nowIsoTimestamp,
      staleBeforeMs,
      batchSize: jobRecoveryBatchSize,
    });
    const recoveredTotal = recoveredBackoffWaitCount + recoveredRunningCount;
    if (recoveredTotal > 0) {
      loggerValue.info("Recovered barcode enrichment jobs.", {
        recoveredBackoffWaitCount,
        recoveredRunningCount,
        recoveredTotal,
        staleBefore: new Date(staleBeforeMs).toISOString(),
      });
    }

    return {
      success: true,
      recoveredBackoffWaitCount,
      recoveredRunningCount,
    };
  }

  return {
    resolveInventoryItemBarcodeOptions,
    enqueueInventoryBarcodeJobsOptions,
    onBarcodeEnrichmentJobWrittenOptions,
    recoverBarcodeEnrichmentJobsOptions,
    resolveInventoryItemBarcodeHandler,
    enqueueInventoryBarcodeJobsHandler,
    onBarcodeEnrichmentJobWrittenHandler,
    recoverBarcodeEnrichmentJobsHandler,
  };
}

const defaultBarcodeHandlers = createBarcodeHandlers();

module.exports = {
  createBarcodeHandlers,
  acquireRateLimitSlot,
  isRateLimitQueueFullError,
  applyRateLimitCooldown,
  waitUntil,
  ...defaultBarcodeHandlers,
};

async function acquireRateLimitSlot({
  dbClient,
  collection,
  documentId,
  minIntervalMs,
  maxWaitMs,
  nowMs,
}) {
  const slot = await acquireRateLimitSlotShared({
    dbClient,
    collection,
    documentId,
    minIntervalMs,
    maxWaitMs,
    nowMs,
    serverTimestampValue: FieldValue.serverTimestamp(),
  });
  if (!slot?.allowed) {
    throw new RateLimitQueueFullError({
      waitMs: slot?.waitMs,
      retryAtMs: slot?.reservedAtMs,
    });
  }
  return slot.reservedAtMs;
}

async function applyRateLimitCooldown({
  dbClient,
  collection,
  documentId,
  cooldownMs,
  nowMs,
}) {
  await applyRateLimitCooldownShared({
    dbClient,
    collection,
    documentId,
    cooldownMs,
    nowMs,
    serverTimestampValue: FieldValue.serverTimestamp(),
  });
}

async function recoverBackoffWaitJobs({
  dbClient,
  jobCollection,
  nowIsoTimestamp,
  nowMs,
  batchSize,
}) {
  const snapshot = await dbClient
    .collection(jobCollection)
    .where("status", "==", "backoff_wait")
    .limit(batchSize)
    .get();

  const dueDocs = snapshot.docs.filter((doc) => {
    const data = doc.data() ?? {};
    const nextAttemptAtMs = readTimestampMs(data.nextAttemptAt);
    return Number.isFinite(nextAttemptAtMs) && nextAttemptAtMs <= nowMs;
  });
  if (dueDocs.length === 0) {
    return 0;
  }

  const batch = dbClient.batch();
  for (const doc of dueDocs) {
    batch.set(
      doc.ref,
      {
        status: "queued",
        updatedAt: nowIsoTimestamp,
        nextAttemptAt: null,
      },
      { merge: true },
    );
  }
  await batch.commit();
  return dueDocs.length;
}

async function recoverStaleRunningJobs({
  dbClient,
  jobCollection,
  nowIsoTimestamp,
  staleBeforeMs,
  batchSize,
}) {
  const snapshot = await dbClient
    .collection(jobCollection)
    .where("status", "==", "running")
    .limit(batchSize)
    .get();

  const staleDocs = snapshot.docs.filter((doc) => {
    const data = doc.data() ?? {};
    const startedAtMs = readTimestampMs(data.startedAt);
    return Number.isFinite(startedAtMs) && startedAtMs <= staleBeforeMs;
  });
  if (staleDocs.length === 0) {
    return 0;
  }

  const batch = dbClient.batch();
  for (const doc of staleDocs) {
    batch.set(
      doc.ref,
      {
        status: "queued",
        updatedAt: nowIsoTimestamp,
        startedAt: null,
        nextAttemptAt: null,
        lastError: "recovered_stuck_running",
      },
      { merge: true },
    );
  }
  await batch.commit();
  return staleDocs.length;
}

function toNonNegativeInt(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return 0;
  }
  return Math.floor(parsed);
}

class RateLimitQueueFullError extends Error {
  constructor({ waitMs, retryAtMs }) {
    super("rate_limit_queue_full");
    this.name = "RateLimitQueueFullError";
    this.waitMs = toNonNegativeInt(waitMs);
    this.retryAtMs = toNonNegativeInt(retryAtMs);
  }
}

function isRateLimitQueueFullError(error) {
  return (
    error instanceof RateLimitQueueFullError ||
    (error &&
      typeof error === "object" &&
      error.name === "RateLimitQueueFullError")
  );
}

function isRateLimitWaitTimeoutError(error) {
  if (!error || typeof error !== "object") {
    return false;
  }

  const name = readString(error.name)?.toLowerCase() ?? "";
  if (name === "ratelimitwaittimeouterror") {
    return true;
  }

  const code = readString(error.code)?.toLowerCase() ?? "";
  if (code === "rate_limit_wait_timeout") {
    return true;
  }

  if (name !== "timeouterror") {
    return false;
  }

  const message = readString(error.message)?.toLowerCase() ?? "";
  return (
    message.includes("rate_limit_wait_timeout") ||
    message.includes("rate limit wait timeout") ||
    (message.includes("rate limit") && message.includes("timeout"))
  );
}
