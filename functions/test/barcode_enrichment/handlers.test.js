const test = require("node:test");
const assert = require("node:assert/strict");

const {
  createBarcodeHandlers,
} = require("../../src/barcode_enrichment/handlers");

function createNoopLogger() {
  return {
    info() {},
    warn() {},
    error() {},
  };
}

function readString(value) {
  return typeof value === "string" && value.trim().length > 0 ?
    value.trim() :
    null;
}

function createRecoveryDb(initialJobs) {
  const state = new Map(
    initialJobs.map((job) => [job.id, { ...job.data }]),
  );

  return {
    state,
    collection() {
      return {
        where(field, operator, expectedValue) {
          if (field !== "status" || operator !== "==") {
            throw new Error("unsupported_query");
          }
          return {
            limit(limitValue) {
              return {
                async get() {
                  const docs = [];
                  for (const [id, data] of state.entries()) {
                    if (data.status !== expectedValue) {
                      continue;
                    }
                    docs.push({
                      id,
                      data() {
                        return { ...data };
                      },
                      ref: { id },
                    });
                    if (docs.length >= limitValue) {
                      break;
                    }
                  }
                  return { docs };
                },
              };
            },
          };
        },
      };
    },
    batch() {
      const writes = [];
      return {
        set(ref, value, options) {
          writes.push({ ref, value, options });
        },
        async commit() {
          for (const write of writes) {
            const current = state.get(write.ref.id) ?? {};
            if (write.options?.merge) {
              state.set(write.ref.id, {
                ...current,
                ...write.value,
              });
            } else {
              state.set(write.ref.id, { ...write.value });
            }
          }
        },
      };
    },
  };
}

test("enqueueInventoryBarcodeJobsHandler returns missing_items for empty list", async () => {
  const handlers = createBarcodeHandlers({
    resolveRequestUidValue: () => "uid-1",
    normalizeEnqueueItemsValue: () => [],
    loggerValue: createNoopLogger(),
    readStringValue: readString,
  });

  const result = await handlers.enqueueInventoryBarcodeJobsHandler({
    data: {
      trigger: "receipt_upload",
      items: [],
    },
  });

  assert.deepEqual(result, {
    success: false,
    queuedCount: 0,
    jobIds: [],
    error: "missing_items",
  });
});

test("enqueueInventoryBarcodeJobsHandler writes queued job to firestore", async () => {
  const setCalls = [];
  let commitCount = 0;
  const dbClient = {
    batch() {
      return {
        set(ref, data, options) {
          setCalls.push({ ref, data, options });
        },
        async commit() {
          commitCount += 1;
        },
      };
    },
    collection(collectionName) {
      return {
        doc(docId) {
          return { collectionName, docId };
        },
      };
    },
  };

  const handlers = createBarcodeHandlers({
    dbClient,
    resolveRequestUidValue: () => "uid-1",
    normalizeEnqueueItemsValue: () => [
      {
        itemId: "item-1",
        itemName: "Bunte Eier",
        fingerprint: "bunte_eier__vom_land",
        brand: "Vom Land",
        storeName: "Kaufland",
        weight: "10 Stk",
      },
    ],
    buildKeywordsValue: () => ["bunte", "eier"],
    buildLookupKeywordsValue: () => ["bunte", "eier"],
    resolveFromGlobalCatalogValue: async () => null,
    composeJobIdValue: () => "job-1",
    loggerValue: createNoopLogger(),
    readStringValue: readString,
  });

  const result = await handlers.enqueueInventoryBarcodeJobsHandler({
    data: {
      trigger: "receipt_upload",
      items: [{}],
    },
  });

  assert.equal(result.success, true);
  assert.equal(result.queuedCount, 1);
  assert.equal(result.resolvedCount, 0);
  assert.deepEqual(result.jobIds, ["job-1"]);
  assert.equal(setCalls.length, 1);
  assert.equal(commitCount, 1);
  assert.equal(setCalls[0].data.status, "queued");
  assert.equal(setCalls[0].data.uid, "uid-1");
  assert.equal(setCalls[0].data.itemId, "item-1");
  assert.deepEqual(setCalls[0].data.keywords, ["bunte", "eier"]);
});

test("onBarcodeEnrichmentJobWrittenHandler marks job failed on resolver error", async () => {
  const markJobFailedCalls = [];
  let markResourceExhaustedCalls = 0;

  const handlers = createBarcodeHandlers({
    acquireRateLimitSlotValue: async () => 0,
    waitUntilValue: async () => {},
    applyRateLimitCooldownValue: async () => {},
    lockQueuedJobValue: async () => ({ shouldProcess: true, attempts: 1 }),
    normalizeJobValue: () => ({
      uid: "uid-1",
      itemId: "item-1",
      itemName: "Bunte Eier",
      fingerprint: "bunte_eier__vom_land",
      trigger: "receipt_upload",
      brand: "Vom Land",
      storeName: "Kaufland",
      weight: "10 Stk",
    }),
    resolveAndPersistItemValue: async () => {
      throw new Error("vertex_500");
    },
    isResourceExhaustedErrorValue: () => false,
    extractErrorMessageValue: (error) => `message=${error.message}`,
    extractErrorDetailsValue: () => null,
    markJobFailedValue: async (payload) => {
      markJobFailedCalls.push(payload);
    },
    markJobResourceExhaustedValue: async () => {
      markResourceExhaustedCalls += 1;
    },
    loggerValue: createNoopLogger(),
  });

  const ref = {
    async get() {
      return {
        exists: true,
        data() {
          return { any: "payload" };
        },
      };
    },
  };

  await handlers.onBarcodeEnrichmentJobWrittenHandler({
    data: {
      after: {
        exists: true,
        ref,
        id: "job-1",
      },
    },
  });

  assert.equal(markJobFailedCalls.length, 1);
  assert.equal(markJobFailedCalls[0].attempts, 1);
  assert.equal(markJobFailedCalls[0].error, "message=vertex_500");
  assert.equal(markResourceExhaustedCalls, 0);
});

test("resolveInventoryItemBarcodeHandler rejects overloaded queue", async () => {
  class TestHttpsError extends Error {
    constructor(code, message, details) {
      super(message);
      this.code = code;
      this.details = details;
    }
  }

  const handlers = createBarcodeHandlers({
    httpsErrorClass: TestHttpsError,
    resolveRequestUidValue: () => "uid-1",
    readStringValue: readString,
    inventoryItemRefValue: () => ({
      async get() {
        return {
          exists: true,
          data() {
            return { name: "Milk" };
          },
        };
      },
    }),
    acquireRateLimitSlotValue: async () => {
      const error = new Error("queue_full");
      error.name = "RateLimitQueueFullError";
      error.waitMs = 80 * 1000;
      throw error;
    },
    loggerValue: createNoopLogger(),
  });

  await assert.rejects(
    handlers.resolveInventoryItemBarcodeHandler({
      data: {
        itemId: "item-1",
      },
    }),
    (error) => {
      assert.equal(error.code, "resource-exhausted");
      assert.equal(error.message, "barcode_lookup_queue_busy");
      assert.equal(error.details?.retryAfterSeconds, 80);
      return true;
    },
  );
});

test("worker routes queue-full errors to resource-exhausted backoff path", async () => {
  const markJobFailedCalls = [];
  const markJobResourceExhaustedCalls = [];
  let cooldownCalls = 0;

  const handlers = createBarcodeHandlers({
    lockQueuedJobValue: async () => ({ shouldProcess: true, attempts: 2 }),
    normalizeJobValue: () => ({
      uid: "uid-1",
      itemId: "item-1",
      itemName: "Bunte Eier",
      fingerprint: "bunte_eier__vom_land",
      trigger: "receipt_upload",
      brand: "Vom Land",
      storeName: "Kaufland",
      weight: "10 Stk",
    }),
    acquireRateLimitSlotValue: async () => {
      const error = new Error("queue_full");
      error.name = "RateLimitQueueFullError";
      error.waitMs = 30 * 1000;
      throw error;
    },
    isResourceExhaustedErrorValue: () => false,
    applyRateLimitCooldownValue: async () => {
      cooldownCalls += 1;
    },
    extractErrorMessageValue: (error) => `message=${error.message}`,
    extractErrorDetailsValue: () => null,
    markJobResourceExhaustedValue: async (payload) => {
      markJobResourceExhaustedCalls.push(payload);
    },
    markJobFailedValue: async (payload) => {
      markJobFailedCalls.push(payload);
    },
    loggerValue: createNoopLogger(),
  });

  const ref = {
    async get() {
      return {
        exists: true,
        data() {
          return { any: "payload" };
        },
      };
    },
  };

  await handlers.onBarcodeEnrichmentJobWrittenHandler({
    data: {
      after: {
        exists: true,
        ref,
        id: "job-queue-full",
      },
    },
  });

  assert.equal(markJobResourceExhaustedCalls.length, 1);
  assert.equal(markJobResourceExhaustedCalls[0].attempts, 2);
  assert.equal(markJobFailedCalls.length, 0);
  assert.equal(cooldownCalls, 0);
});

test("worker routes rate-limit wait timeout to resource-exhausted backoff path", async () => {
  const markJobFailedCalls = [];
  const markJobResourceExhaustedCalls = [];

  const handlers = createBarcodeHandlers({
    lockQueuedJobValue: async () => ({ shouldProcess: true, attempts: 3 }),
    normalizeJobValue: () => ({
      uid: "uid-1",
      itemId: "item-1",
      itemName: "Bunte Eier",
      fingerprint: "bunte_eier__vom_land",
      trigger: "receipt_upload",
      brand: "Vom Land",
      storeName: "Kaufland",
      weight: "10 Stk",
    }),
    acquireRateLimitSlotValue: async () => Date.now(),
    waitUntilValue: async () => {
      const error = new Error("rate_limit_wait_timeout");
      error.name = "RateLimitWaitTimeoutError";
      throw error;
    },
    isResourceExhaustedErrorValue: () => false,
    extractErrorMessageValue: (error) => `message=${error.message}`,
    extractErrorDetailsValue: () => null,
    markJobResourceExhaustedValue: async (payload) => {
      markJobResourceExhaustedCalls.push(payload);
    },
    markJobFailedValue: async (payload) => {
      markJobFailedCalls.push(payload);
    },
    loggerValue: createNoopLogger(),
  });

  const ref = {
    async get() {
      return {
        exists: true,
        data() {
          return { any: "payload" };
        },
      };
    },
  };

  await handlers.onBarcodeEnrichmentJobWrittenHandler({
    data: {
      after: {
        exists: true,
        ref,
        id: "job-rate-limit-timeout",
      },
    },
  });

  assert.equal(markJobResourceExhaustedCalls.length, 1);
  assert.equal(markJobResourceExhaustedCalls[0].attempts, 3);
  assert.equal(markJobFailedCalls.length, 0);
});

test("recoverBarcodeEnrichmentJobsHandler recovers due jobs", async () => {
  const nowMs = Date.parse("2026-03-08T12:00:00.000Z");
  let backoffInput = null;
  let runningInput = null;

  const handlers = createBarcodeHandlers({
    nowMsValue: () => nowMs,
    runningJobStaleMs: 10 * 60 * 1000,
    jobRecoveryBatchSize: 25,
    recoverBackoffWaitJobsValue: async (input) => {
      backoffInput = input;
      return 2;
    },
    recoverStaleRunningJobsValue: async (input) => {
      runningInput = input;
      return 1;
    },
    loggerValue: createNoopLogger(),
  });

  const result = await handlers.recoverBarcodeEnrichmentJobsHandler();

  assert.equal(result.success, true);
  assert.equal(result.recoveredBackoffWaitCount, 2);
  assert.equal(result.recoveredRunningCount, 1);
  assert.equal(backoffInput.batchSize, 25);
  assert.equal(runningInput.batchSize, 25);
  assert.equal(backoffInput.nowMs, nowMs);
  assert.equal(
    runningInput.staleBeforeMs,
    nowMs - (10 * 60 * 1000),
  );
});

test("recoverBarcodeEnrichmentJobsHandler requeues due and stale jobs", async () => {
  const nowMs = Date.parse("2026-03-08T12:00:00.000Z");
  const nowIso = "2026-03-08T12:00:00.000Z";
  const dbClient = createRecoveryDb([
    {
      id: "job-backoff-due",
      data: {
        status: "backoff_wait",
        nextAttemptAt: "2026-03-08T11:59:40.000Z",
      },
    },
    {
      id: "job-backoff-future",
      data: {
        status: "backoff_wait",
        nextAttemptAt: "2026-03-08T12:00:20.000Z",
      },
    },
    {
      id: "job-running-stale",
      data: {
        status: "running",
        startedAt: "2026-03-08T11:40:00.000Z",
      },
    },
    {
      id: "job-running-fresh",
      data: {
        status: "running",
        startedAt: "2026-03-08T11:59:30.000Z",
      },
    },
  ]);

  const handlers = createBarcodeHandlers({
    dbClient,
    nowMsValue: () => nowMs,
    runningJobStaleMs: 10 * 60 * 1000,
    jobRecoveryBatchSize: 100,
    loggerValue: createNoopLogger(),
  });

  const result = await handlers.recoverBarcodeEnrichmentJobsHandler();

  assert.equal(result.success, true);
  assert.equal(result.recoveredBackoffWaitCount, 1);
  assert.equal(result.recoveredRunningCount, 1);

  const backoffDue = dbClient.state.get("job-backoff-due");
  assert.equal(backoffDue.status, "queued");
  assert.equal(backoffDue.nextAttemptAt, null);
  assert.equal(backoffDue.updatedAt, nowIso);

  const backoffFuture = dbClient.state.get("job-backoff-future");
  assert.equal(backoffFuture.status, "backoff_wait");

  const runningStale = dbClient.state.get("job-running-stale");
  assert.equal(runningStale.status, "queued");
  assert.equal(runningStale.startedAt, null);
  assert.equal(runningStale.nextAttemptAt, null);
  assert.equal(runningStale.lastError, "recovered_stuck_running");
  assert.equal(runningStale.updatedAt, nowIso);

  const runningFresh = dbClient.state.get("job-running-fresh");
  assert.equal(runningFresh.status, "running");
});
