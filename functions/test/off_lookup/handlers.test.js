const test = require("node:test");
const assert = require("node:assert/strict");

const {
  createOffLookupHandlers,
  CACHE_STATUS_FOUND,
  CACHE_STATUS_NOT_FOUND,
} = require("../../src/off_lookup/handlers");

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

test("resolveOffProductByBarcode returns invalid_barcode", async () => {
  const handlers = createOffLookupHandlers({
    resolveRequestUidValue: () => "uid-1",
    readStringValue: readString,
    normalizeBarcodeValue: () => "",
    loggerValue: createNoopLogger(),
  });

  const result = await handlers.resolveOffProductByBarcodeHandler({
    data: {
      barcode: "invalid",
    },
  });

  assert.deepEqual(result, {
    success: false,
    found: false,
    fromCache: false,
    error: "invalid_barcode",
  });
});

test("resolveOffProductByBarcode returns fresh cache hit", async () => {
  let fetchCalls = 0;

  const handlers = createOffLookupHandlers({
    resolveRequestUidValue: () => "uid-1",
    readStringValue: readString,
    normalizeBarcodeValue: (value) => value,
    nowMsValue: () => 1000,
    readCacheEntryValue: async () => ({
      status: CACHE_STATUS_FOUND,
      isFresh: true,
      product: {
        barcode: "4006381333931",
        name: "Cached Milk",
      },
    }),
    fetchOffProductValue: async () => {
      fetchCalls += 1;
      return {
        status: CACHE_STATUS_NOT_FOUND,
        product: null,
      };
    },
    loggerValue: createNoopLogger(),
  });

  const result = await handlers.resolveOffProductByBarcodeHandler({
    data: {
      barcode: "4006381333931",
    },
  });

  assert.equal(result.success, true);
  assert.equal(result.found, true);
  assert.equal(result.fromCache, true);
  assert.equal(result.stale, false);
  assert.equal(result.product?.name, "Cached Milk");
  assert.equal(fetchCalls, 0);
});

test("resolveOffProductByBarcode fetches and writes cache on miss", async () => {
  const writeCalls = [];
  const handlers = createOffLookupHandlers({
    resolveRequestUidValue: () => "uid-1",
    readStringValue: readString,
    normalizeBarcodeValue: (value) => value,
    nowMsValue: () => 1000,
    readCacheEntryValue: async () => null,
    acquireOffProductSlotValue: async () => 1000,
    fetchOffProductValue: async () => ({
      status: CACHE_STATUS_FOUND,
      product: {
        barcode: "4006381333931",
        name: "OFF Milk",
      },
    }),
    writeCacheEntryValue: async (payload) => {
      writeCalls.push(payload);
    },
    loggerValue: createNoopLogger(),
  });

  const result = await handlers.resolveOffProductByBarcodeHandler({
    data: {
      barcode: "4006381333931",
    },
  });

  assert.equal(result.success, true);
  assert.equal(result.found, true);
  assert.equal(result.fromCache, false);
  assert.equal(result.product?.name, "OFF Milk");
  assert.equal(writeCalls.length, 1);
  assert.equal(writeCalls[0].status, CACHE_STATUS_FOUND);
  assert.equal(writeCalls[0].barcode, "4006381333931");
});

test("resolveOffProductByBarcode writes not_found on miss", async () => {
  const writeCalls = [];
  const handlers = createOffLookupHandlers({
    resolveRequestUidValue: () => "uid-1",
    readStringValue: readString,
    normalizeBarcodeValue: (value) => value,
    nowMsValue: () => 1000,
    readCacheEntryValue: async () => null,
    acquireOffProductSlotValue: async () => 1000,
    fetchOffProductValue: async () => ({
      status: CACHE_STATUS_NOT_FOUND,
      product: null,
    }),
    writeCacheEntryValue: async (payload) => {
      writeCalls.push(payload);
    },
    loggerValue: createNoopLogger(),
  });

  const result = await handlers.resolveOffProductByBarcodeHandler({
    data: {
      barcode: "4006381333931",
    },
  });

  assert.equal(result.success, true);
  assert.equal(result.found, false);
  assert.equal(result.fromCache, false);
  assert.equal(writeCalls.length, 1);
  assert.equal(writeCalls[0].status, CACHE_STATUS_NOT_FOUND);
});

test("resolveOffProductByBarcode falls back to stale cache on fetch error", async () => {
  const handlers = createOffLookupHandlers({
    resolveRequestUidValue: () => "uid-1",
    readStringValue: readString,
    normalizeBarcodeValue: (value) => value,
    nowMsValue: () => 1000,
    readCacheEntryValue: async () => ({
      status: CACHE_STATUS_FOUND,
      isFresh: false,
      product: {
        barcode: "4006381333931",
        name: "Stale Cached Milk",
      },
    }),
    acquireOffProductSlotValue: async () => 1000,
    fetchOffProductValue: async () => {
      throw new Error("off_down");
    },
    loggerValue: createNoopLogger(),
  });

  const result = await handlers.resolveOffProductByBarcodeHandler({
    data: {
      barcode: "4006381333931",
    },
  });

  assert.equal(result.success, true);
  assert.equal(result.found, true);
  assert.equal(result.fromCache, true);
  assert.equal(result.stale, true);
  assert.equal(result.product?.name, "Stale Cached Milk");
});
