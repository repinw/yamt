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
