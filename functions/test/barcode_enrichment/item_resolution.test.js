const test = require("node:test");
const assert = require("node:assert/strict");

const {
  createItemResolutionService,
} = require("../../src/barcode_enrichment/item_resolution");

function createMemoryItemRef() {
  const writes = [];
  const ref = {
    async get() {
      return { exists: true };
    },
    async set(data, options) {
      writes.push({ data, options });
    },
  };
  return { ref, writes };
}

function createNoopLogger() {
  return {
    info() {},
    warn() {},
    error() {},
  };
}

test("resolveAndPersistItem propagates upstream 500 errors", async () => {
  const memory = createMemoryItemRef();
  const service = createItemResolutionService({
    nowIsoValue: () => "2026-03-04T10:00:00.000Z",
    buildKeywordsValue: () => ["keyword"],
    buildLookupKeywordsValue: () => ["lookup"],
    resolveFromGlobalCatalogValue: async () => null,
    resolveCandidatesValue: async () => {
      throw new Error("vertex_500");
    },
    loggerValue: createNoopLogger(),
  });

  await assert.rejects(
    service.resolveAndPersistItem({
      uid: "uid-1",
      itemId: "item-1",
      itemName: "Bunte Eier",
      brand: "Vom Land",
      storeName: "Kaufland",
      weight: "10 Stk",
      fingerprint: "bunte_eier__vom_land",
      trigger: "manual_search",
      itemRef: memory.ref,
    }),
    /vertex_500/,
  );

  assert.equal(memory.writes.length >= 1, true);
  assert.equal(memory.writes[0].data.foodFingerprint, "bunte_eier__vom_land");
});

test("resolveAndPersistItem propagates timeout-like errors", async () => {
  const memory = createMemoryItemRef();
  const service = createItemResolutionService({
    nowIsoValue: () => "2026-03-04T10:00:00.000Z",
    buildKeywordsValue: () => ["keyword"],
    buildLookupKeywordsValue: () => ["lookup"],
    resolveFromGlobalCatalogValue: async () => null,
    resolveCandidatesValue: async () => {
      throw new Error("timeout");
    },
    loggerValue: createNoopLogger(),
  });

  await assert.rejects(
    service.resolveAndPersistItem({
      uid: "uid-1",
      itemId: "item-1",
      itemName: "Bunte Eier",
      brand: "Vom Land",
      storeName: "Kaufland",
      weight: "10 Stk",
      fingerprint: "bunte_eier__vom_land",
      trigger: "manual_search",
      itemRef: memory.ref,
    }),
    /timeout/,
  );
});

test("resolveAndPersistItem persists uncertain AI barcode flag", async () => {
  const memory = createMemoryItemRef();
  const upsertCalls = [];
  const service = createItemResolutionService({
    nowIsoValue: () => "2026-03-04T10:00:00.000Z",
    buildKeywordsValue: () => ["keyword"],
    buildLookupKeywordsValue: () => ["lookup"],
    resolveFromGlobalCatalogValue: async () => null,
    resolveCandidatesValue: async () => ({
      candidates: ["4006381333931"],
      uncertain: true,
    }),
    upsertGlobalResolutionValue: async (payload) => {
      upsertCalls.push(payload);
    },
    loggerValue: createNoopLogger(),
  });

  const result = await service.resolveAndPersistItem({
    uid: "uid-1",
    itemId: "item-1",
    itemName: "Bunte Eier",
    brand: "Vom Land",
    storeName: "Kaufland",
    weight: "10 Stk",
    fingerprint: "bunte_eier__vom_land",
    trigger: "manual_search",
    itemRef: memory.ref,
  });

  assert.equal(result.found, true);
  assert.equal(result.barcode, "4006381333931");
  assert.equal(result.uncertain, true);
  assert.equal(upsertCalls.length, 1);
  assert.equal(upsertCalls[0].barcodeLookupUncertain, true);

  const resolvedWrite = memory.writes[memory.writes.length - 1];
  assert.equal(resolvedWrite.data.barcodeLookupUncertain, true);
});
