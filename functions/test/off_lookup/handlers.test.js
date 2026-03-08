const test = require("node:test");
const assert = require("node:assert/strict");

const {
  createOffLookupHandlers,
  CACHE_STATUS_FOUND,
  CACHE_STATUS_NOT_FOUND,
  buildProfileFromOffProduct,
  isRetriableOffRequestError,
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

test("buildProfileFromOffProduct uses barcode when name is missing", () => {
  const barcode = "4006381333931";
  const profile = buildProfileFromOffProduct({
    barcode,
    product: {
      brands: "Test Brand",
      nutriments: {
        "energy-kcal_100g": 120,
      },
    },
    nowMs: Date.parse("2026-03-08T12:00:00.000Z"),
  });

  assert.equal(profile?.barcode, barcode);
  assert.equal(profile?.name, barcode);
  assert.equal(profile?.per100_kcal, 120);
});

test("buildProfileFromOffProduct returns null when no name, kcal, or image", () => {
  const profile = buildProfileFromOffProduct({
    barcode: "4006381333931",
    product: {
      brands: "Test Brand",
      nutriments: {},
    },
    nowMs: Date.parse("2026-03-08T12:00:00.000Z"),
  });

  assert.equal(profile, null);
});

test("isRetriableOffRequestError detects retryable errors", () => {
  assert.equal(
    isRetriableOffRequestError({
      name: "AbortError",
      message: "This operation was aborted",
    }),
    true,
  );
  assert.equal(
    isRetriableOffRequestError({
      code: 20,
      message: "This operation was aborted",
    }),
    true,
  );
  assert.equal(
    isRetriableOffRequestError({
      message: "off_http_429",
    }),
    true,
  );
  assert.equal(
    isRetriableOffRequestError({
      message: "off_http_503",
    }),
    true,
  );
  assert.equal(
    isRetriableOffRequestError({
      message: "Connection closed before full header was received",
    }),
    true,
  );
});

test("isRetriableOffRequestError skips non-retryable errors", () => {
  assert.equal(
    isRetriableOffRequestError({
      message: "off_http_403",
    }),
    false,
  );
  assert.equal(
    isRetriableOffRequestError({
      message: "invalid_barcode",
    }),
    false,
  );
});
