const {
  db,
  FieldValue,
  GLOBAL_RESOLUTIONS_COLLECTION,
  KEYWORD_ALIAS_MIN_SCORE,
  KEYWORD_MATCH_MIN_SCORE,
  MAX_KEYWORD_QUERY_TERMS,
  KEYWORD_QUERY_LIMIT,
  LOOKUP_GENERIC_TOKENS,
} = require("./runtime");
const {
  buildKeywords,
  buildLookupKeywords,
  normalizeForLookup,
  normalizeBarcode,
  ensureCandidatesContainBarcode,
  tokenizeForLookup,
  readPositiveInt,
  readBoolean,
  readString,
  nowIso,
  globalResolutionRef,
} = require("./helpers");

async function resolveFromGlobalCatalog({
  fingerprint,
  itemName,
  brand,
  weight,
  lookupKeywords,
}) {
  const exactMatch = await readGlobalResolutionByFingerprint(fingerprint);
  if (exactMatch?.barcode) {
    return {
      matchedFingerprint: fingerprint,
      barcode: exactMatch.barcode,
      barcodeCandidates: exactMatch.barcodeCandidates,
      barcodeLookupUncertain: exactMatch.barcodeLookupUncertain,
      matchType: "exact",
      score: 100,
    };
  }

  const keywords = (lookupKeywords ?? buildLookupKeywords({
    itemName,
    brand,
    weight,
  }))
    .map((keyword) => normalizeForLookup(keyword))
    .filter((keyword) => keyword && keyword.length >= 3)
    .slice(0, MAX_KEYWORD_QUERY_TERMS);
  if (keywords.length === 0) {
    return null;
  }

  const keywordSnapshot = await db
    .collection(GLOBAL_RESOLUTIONS_COLLECTION)
    .where("keywords", "array-contains-any", keywords)
    .limit(KEYWORD_QUERY_LIMIT)
    .get();
  if (keywordSnapshot.empty) {
    return null;
  }

  const rankedMatches = [];
  for (const doc of keywordSnapshot.docs) {
    const data = doc.data() ?? {};
    const source = readString(data.source);
    if (source === "global_keyword_match") {
      const keywordMatchScore = readPositiveInt(data.keywordMatchScore);
      if (keywordMatchScore < KEYWORD_ALIAS_MIN_SCORE) {
        continue;
      }
    }
    const barcode = normalizeBarcode(data.barcode);
    if (!barcode) {
      continue;
    }
    const candidates = ensureCandidatesContainBarcode(
      data.barcodeCandidates,
      barcode,
    );
    const match = scoreKeywordMatch({
      data,
      itemName,
      brand,
      lookupKeywords: keywords,
    });
    if (!isKeywordMatchReliable(match)) {
      continue;
    }
    rankedMatches.push({
      matchedFingerprint: doc.id,
      barcode,
      barcodeCandidates: candidates,
      barcodeLookupUncertain: readBoolean(data.barcodeLookupUncertain),
      matchType: "keyword",
      score: match.score,
    });
  }
  if (rankedMatches.length === 0) {
    return null;
  }

  rankedMatches.sort((left, right) => {
    const byScore = right.score - left.score;
    if (byScore !== 0) {
      return byScore;
    }
    const byCandidateCount =
      right.barcodeCandidates.length - left.barcodeCandidates.length;
    if (byCandidateCount !== 0) {
      return byCandidateCount;
    }
    return left.matchedFingerprint.localeCompare(right.matchedFingerprint);
  });

  return rankedMatches[0];
}

async function readGlobalResolutionByFingerprint(fingerprint) {
  const snapshot = await globalResolutionRef(fingerprint).get();
  if (!snapshot.exists) {
    return null;
  }
  const data = snapshot.data() ?? {};
  const source = readString(data.source);
  if (source === "global_keyword_match") {
    const keywordMatchScore = readPositiveInt(data.keywordMatchScore);
    if (keywordMatchScore < KEYWORD_ALIAS_MIN_SCORE) {
      return null;
    }
  }
  const barcode = normalizeBarcode(data.barcode);
  if (!barcode) {
    return null;
  }
  return {
    barcode,
    barcodeCandidates: ensureCandidatesContainBarcode(
      data.barcodeCandidates,
      barcode,
    ),
    barcodeLookupUncertain: readBoolean(data.barcodeLookupUncertain),
  };
}

function scoreKeywordMatch({ data, itemName, brand, lookupKeywords }) {
  const itemNameNormalized = normalizeForLookup(itemName);
  const brandNormalized = normalizeForLookup(brand);
  const nameNormalized = normalizeForLookup(data.itemName) ??
    normalizeForLookup(data.nameNormalized);
  const docBrandNormalized = normalizeForLookup(data.brand) ??
    normalizeForLookup(data.brandNormalized);
  const hasBrandInput = Boolean(brandNormalized);
  const itemNameTokens = tokenizeForLookup(itemName);
  const docNameTokens = tokenizeForLookup(nameNormalized);
  const itemTokenSet = new Set(itemNameTokens);
  const docTokenSet = new Set(docNameTokens);
  const tokenIntersectionCount = countSetIntersection(itemTokenSet, docTokenSet);
  const itemTokenCoverage = itemTokenSet.size > 0 ?
    tokenIntersectionCount / itemTokenSet.size :
    0;
  const docTokenCoverage = docTokenSet.size > 0 ?
    tokenIntersectionCount / docTokenSet.size :
    0;
  const distinctiveItemTokens = Array.from(itemTokenSet).filter((token) => {
    return !LOOKUP_GENERIC_TOKENS.has(token);
  });
  const distinctiveDocTokens = Array.from(docTokenSet).filter((token) => {
    return !LOOKUP_GENERIC_TOKENS.has(token);
  });
  const distinctiveItemSet = new Set(distinctiveItemTokens);
  const distinctiveDocSet = new Set(distinctiveDocTokens);
  const sharedDistinctiveCount = countSetIntersection(
    distinctiveItemSet,
    distinctiveDocSet,
  );
  const unmatchedDistinctiveItemCount =
    distinctiveItemTokens.length - sharedDistinctiveCount;
  const nameJaccard = jaccardScore(itemNameTokens, docNameTokens);

  let nameScore = 0;
  if (itemNameNormalized && nameNormalized) {
    if (itemNameNormalized === nameNormalized) {
      nameScore = 10;
    } else if (itemTokenCoverage >= 0.95 && tokenIntersectionCount >= 2) {
      nameScore = 8;
    } else if (nameJaccard >= 0.85) {
      nameScore = 8;
    } else if (nameJaccard >= 0.6) {
      nameScore = 6;
    } else if (nameJaccard >= 0.4) {
      nameScore = 3;
    }
  }

  let brandScore = 0;
  if (brandNormalized && docBrandNormalized) {
    if (brandNormalized === docBrandNormalized) {
      brandScore = 4;
    } else if (
      docBrandNormalized.includes(brandNormalized) ||
      brandNormalized.includes(docBrandNormalized)
    ) {
      brandScore = 2;
    }
  }

  const docKeywords = Array.isArray(data.keywords) ?
    data.keywords
      .map((keyword) => normalizeForLookup(keyword))
      .filter((keyword) => keyword && keyword.length >= 3) :
    [];
  const docKeywordSet = new Set(docKeywords);
  let overlapCount = 0;
  for (const keyword of lookupKeywords) {
    if (docKeywordSet.has(keyword)) {
      overlapCount += 1;
    }
  }

  let nameTokenOverlap = 0;
  for (const token of itemNameTokens) {
    if (docKeywordSet.has(token)) {
      nameTokenOverlap += 1;
    }
  }

  let score = nameScore + brandScore;
  score += Math.min(overlapCount, 4);
  score += Math.min(nameTokenOverlap, 4);
  score += Math.min(sharedDistinctiveCount, 2);

  return {
    score,
    nameScore,
    brandScore,
    overlapCount,
    nameTokenOverlap,
    hasBrandInput,
    nameJaccard,
    tokenIntersectionCount,
    itemTokenCoverage,
    docTokenCoverage,
    sharedDistinctiveCount,
    unmatchedDistinctiveItemCount,
    distinctiveItemTokenCount: distinctiveItemTokens.length,
    distinctiveDocTokenCount: distinctiveDocTokens.length,
    itemNameTokenCount: itemNameTokens.length,
    docNameTokenCount: docNameTokens.length,
  };
}

function isKeywordMatchReliable(match) {
  if (!match) {
    return false;
  }
  if (match.score < KEYWORD_MATCH_MIN_SCORE) {
    return false;
  }

  const strongTokenCoverage = match.itemTokenCoverage >= 0.75;
  const strongName = match.nameScore >= 6 || strongTokenCoverage;
  const hasNameTokenOverlap = match.nameTokenOverlap >= 1;
  if (!strongName && !hasNameTokenOverlap) {
    return false;
  }

  if (
    match.distinctiveItemTokenCount > 0 &&
    match.sharedDistinctiveCount === 0 &&
    match.nameScore < 10
  ) {
    return false;
  }

  if (
    match.unmatchedDistinctiveItemCount > 0 &&
    match.itemTokenCoverage < 0.75 &&
    match.nameScore < 10
  ) {
    return false;
  }

  if (
    match.nameJaccard < 0.45 &&
    !strongTokenCoverage &&
    match.nameScore < 10
  ) {
    return false;
  }

  if (!strongName && match.overlapCount < 2) {
    return false;
  }

  if (
    match.hasBrandInput &&
    match.brandScore === 0 &&
    match.nameScore < 10 &&
    !strongTokenCoverage &&
    match.overlapCount < 3
  ) {
    return false;
  }

  return true;
}

function jaccardScore(leftTokens, rightTokens) {
  if (!Array.isArray(leftTokens) || !Array.isArray(rightTokens)) {
    return 0;
  }
  const left = new Set(leftTokens);
  const right = new Set(rightTokens);
  if (left.size === 0 || right.size === 0) {
    return 0;
  }
  let intersection = 0;
  for (const token of left) {
    if (right.has(token)) {
      intersection += 1;
    }
  }
  const union = left.size + right.size - intersection;
  if (union <= 0) {
    return 0;
  }
  return intersection / union;
}

function countSetIntersection(leftSet, rightSet) {
  if (!(leftSet instanceof Set) || !(rightSet instanceof Set)) {
    return 0;
  }
  if (leftSet.size === 0 || rightSet.size === 0) {
    return 0;
  }
  let intersection = 0;
  for (const token of leftSet) {
    if (rightSet.has(token)) {
      intersection += 1;
    }
  }
  return intersection;
}

async function upsertGlobalResolution({
  fingerprint,
  barcode,
  candidates,
  barcodeLookupUncertain,
  itemName,
  brand,
  storeName,
  weight,
  source,
  keywordMatchScore,
  uid,
}) {
  const keywords = buildKeywords({
    itemName,
    brand,
    storeName,
    weight,
    fingerprint,
  });
  await globalResolutionRef(fingerprint).set(
    {
      fingerprint,
      barcode,
      barcodeCandidates: ensureCandidatesContainBarcode(candidates, barcode),
      barcodeLookupUncertain: readBoolean(barcodeLookupUncertain),
      itemName,
      brand: brand ?? null,
      nameNormalized: normalizeForLookup(itemName),
      brandNormalized: normalizeForLookup(brand),
      keywords,
      source,
      keywordMatchScore: Number.isFinite(Number(keywordMatchScore)) ?
        Number(keywordMatchScore) :
        null,
      lastResolvedBy: uid,
      hitCount: FieldValue.increment(1),
      updatedAt: nowIso(),
    },
    { merge: true },
  );
}

async function touchGlobalResolution(fingerprint) {
  if (!fingerprint) {
    return;
  }
  await globalResolutionRef(fingerprint).set(
    {
      hitCount: FieldValue.increment(1),
      lastHitAt: nowIso(),
      updatedAt: nowIso(),
    },
    { merge: true },
  );
}

module.exports = {
  resolveFromGlobalCatalog,
  readGlobalResolutionByFingerprint,
  scoreKeywordMatch,
  isKeywordMatchReliable,
  jaccardScore,
  countSetIntersection,
  upsertGlobalResolution,
  touchGlobalResolution,
};
