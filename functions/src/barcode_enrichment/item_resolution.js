const logger = require("firebase-functions/logger");
const { KEYWORD_ALIAS_MIN_SCORE } = require("./runtime");
const {
  nowIso,
  buildKeywords,
  buildLookupKeywords,
  ensureCandidatesContainBarcode,
  normalizeCandidates,
  inventoryItemRef,
} = require("./helpers");
const { resolveCandidates } = require("./ai");
const {
  resolveFromGlobalCatalog,
  touchGlobalResolution,
  upsertGlobalResolution,
} = require("./global_catalog");

function createItemResolutionService({
  nowIsoValue = nowIso,
  buildKeywordsValue = buildKeywords,
  buildLookupKeywordsValue = buildLookupKeywords,
  ensureCandidatesContainBarcodeValue = ensureCandidatesContainBarcode,
  normalizeCandidatesValue = normalizeCandidates,
  inventoryItemRefValue = inventoryItemRef,
  resolveCandidatesValue = resolveCandidates,
  resolveFromGlobalCatalogValue = resolveFromGlobalCatalog,
  touchGlobalResolutionValue = touchGlobalResolution,
  upsertGlobalResolutionValue = upsertGlobalResolution,
  loggerValue = logger,
  keywordAliasMinScore = KEYWORD_ALIAS_MIN_SCORE,
} = {}) {
  async function resolveAndPersistItem({
    uid,
    itemId,
    itemName,
    brand,
    storeName,
    weight,
    fingerprint,
    trigger,
    itemRef,
  }) {
    const resolvedItemRef = itemRef ?? inventoryItemRefValue(uid, itemId);
    const itemSnapshot = await resolvedItemRef.get();
    if (!itemSnapshot.exists) {
      throw new Error("item_not_found");
    }

    const requestedAt = nowIsoValue();
    const searchKeywords = buildKeywordsValue({
      itemName,
      brand,
      storeName,
      weight,
      fingerprint,
    });
    const lookupKeywords = buildLookupKeywordsValue({
      itemName,
      brand,
      weight,
    });

    await resolvedItemRef.set(
      {
        foodFingerprint: fingerprint,
        barcodeLookupRequestedAt: requestedAt,
        searchKeywords,
      },
      { merge: true },
    );

    const cachedResolution = await resolveFromGlobalCatalogValue({
      fingerprint,
      itemName,
      brand,
      weight,
      lookupKeywords,
    });
    if (cachedResolution?.barcode) {
      const mergedCandidates = ensureCandidatesContainBarcodeValue(
        cachedResolution.barcodeCandidates,
        cachedResolution.barcode,
      );
      await persistItemResolved({
        itemRef: resolvedItemRef,
        fingerprint,
        requestedAt,
        barcode: cachedResolution.barcode,
        candidates: mergedCandidates,
        searchKeywords,
      });
      await touchGlobalResolutionValue(cachedResolution.matchedFingerprint);
      if (
        cachedResolution.matchedFingerprint !== fingerprint &&
        cachedResolution.matchType === "keyword" &&
        cachedResolution.score >= keywordAliasMinScore
      ) {
        await upsertGlobalResolutionValue({
          fingerprint,
          barcode: cachedResolution.barcode,
          candidates: mergedCandidates,
          itemName,
          brand,
          storeName,
          weight,
          source: "global_keyword_match",
          keywordMatchScore: cachedResolution.score,
          uid,
        });
      }
      loggerValue.info("Inventory item resolved from global cache.", {
        uid,
        itemId,
        fingerprint,
        barcode: cachedResolution.barcode,
        matchType: cachedResolution.matchType,
        trigger,
      });
      return {
        found: true,
        barcode: cachedResolution.barcode,
        candidates: mergedCandidates,
        source: cachedResolution.matchType === "keyword" ?
          "global_keyword_match" :
          "global_cache",
      };
    }

    const candidates = await resolveCandidatesValue({
      itemName,
      brand,
      storeName,
      weight,
    });
    const barcode = candidates.length > 0 ? candidates[0] : null;
    if (barcode) {
      await persistItemResolved({
        itemRef: resolvedItemRef,
        fingerprint,
        requestedAt,
        barcode,
        candidates,
        searchKeywords,
      });
      await upsertGlobalResolutionValue({
        fingerprint,
        barcode,
        candidates,
        itemName,
        brand,
        storeName,
        weight,
        source: "ai_single",
        uid,
      });
      loggerValue.info("Inventory item barcode resolved.", {
        uid,
        itemId,
        fingerprint,
        barcode,
        trigger,
      });
      return {
        found: true,
        barcode,
        candidates,
        source: "ai_single",
      };
    }

    await persistItemUnresolved({
      itemRef: resolvedItemRef,
      fingerprint,
      requestedAt,
      candidates,
      searchKeywords,
    });
    loggerValue.info("Inventory item barcode unresolved.", {
      uid,
      itemId,
      fingerprint,
      trigger,
    });
    return {
      found: false,
      barcode: null,
      candidates,
      source: "ai_single",
    };
  }

  async function persistItemResolved({
    itemRef,
    fingerprint,
    requestedAt,
    barcode,
    candidates,
    searchKeywords,
  }) {
    await itemRef.set(
      {
        barcode,
        barcodeCandidates: ensureCandidatesContainBarcodeValue(
          candidates,
          barcode,
        ),
        barcodeResolvedAt: nowIsoValue(),
        barcodeLookupRequestedAt: requestedAt,
        foodFingerprint: fingerprint,
        searchKeywords,
      },
      { merge: true },
    );
  }

  async function persistItemUnresolved({
    itemRef,
    fingerprint,
    requestedAt,
    candidates,
    searchKeywords,
  }) {
    await itemRef.set(
      {
        barcodeCandidates: normalizeCandidatesValue(candidates),
        barcodeLookupRequestedAt: requestedAt,
        foodFingerprint: fingerprint,
        searchKeywords,
      },
      { merge: true },
    );
  }

  return {
    resolveAndPersistItem,
    persistItemResolved,
    persistItemUnresolved,
  };
}

const defaultItemResolutionService = createItemResolutionService();

module.exports = {
  createItemResolutionService,
  ...defaultItemResolutionService,
};
