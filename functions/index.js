const { onCall } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const { GoogleGenAI, ThinkingLevel } = require("@google/genai");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

admin.initializeApp();

const db = admin.firestore();

const USERS_COLLECTION = "users";
const INVENTORY_ITEMS_COLLECTION = "inventory_items";
const JOB_COLLECTION = "barcode_enrichment_jobs";
const GLOBAL_RESOLUTIONS_COLLECTION = "global_food_resolutions";

const FUNCTION_REGION = "europe-west1";
const MODEL_NAME = "gemini-3.1-pro-preview";
const MODEL_LOCATION = "global";
const MODEL_THINKING_LEVEL = ThinkingLevel.HIGH;
const MAX_OUTPUT_TOKENS = 2048;
const MAX_CANDIDATES_PER_ITEM = 5;
const MAX_ENQUEUE_ITEMS = 40;
const MAX_JOB_RETRIES = 2;
const MAX_JOB_ATTEMPTS = MAX_JOB_RETRIES + 1;
const WORKER_MAX_INSTANCES = 7;
const MAX_KEYWORD_QUERY_TERMS = 8;
const KEYWORD_QUERY_LIMIT = 12;
const KEYWORD_MATCH_MIN_SCORE = 9;
const KEYWORD_ALIAS_MIN_SCORE = 12;
const LOOKUP_STOPWORDS = new Set([
  "unknown",
  "none",
  "artikel",
  "product",
  "lebensmittel",
  "sort",
  "sorte",
  "vom",
  "von",
  "und",
  "oder",
  "mit",
  "ohne",
  "land",
]);
const LOOKUP_GENERIC_TOKENS = new Set([
  "lebensmittel",
  "artikel",
  "produkt",
  "food",
  "milch",
  "brot",
  "kaese",
  "fleisch",
  "hackfleisch",
  "filet",
  "eier",
  "ei",
  "wurst",
  "snack",
]);
const LOOKUP_TOKEN_ALIASES = new Map([
  ["haehn", "haehnchen"],
  ["haehnch", "haehnchen"],
  ["huehn", "haehnchen"],
  ["huhn", "haehnchen"],
  ["brst", "brust"],
  ["thunf", "thunfisch"],
  ["eig", "eigenem"],
  ["sort", "sortiert"],
]);

const ai = new GoogleGenAI({
  vertexai: true,
  project: process.env.GCLOUD_PROJECT ?? process.env.PROJECT_ID,
  location: MODEL_LOCATION,
});

exports.resolveInventoryItemBarcode = onCall(
  {
    region: FUNCTION_REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
    enforceAppCheck: false,
  },
  async (request) => {
    const uid = request.auth?.uid ?? readString(request.data?.userId);
    if (!uid) {
      return {
        success: false,
        found: false,
        barcode: null,
        candidates: [],
        error: "missing_user",
      };
    }

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
  },
);

exports.enqueueInventoryBarcodeJobs = onCall(
  {
    region: FUNCTION_REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    enforceAppCheck: false,
  },
  async (request) => {
    const uid = request.auth?.uid ?? readString(request.data?.userId);
    if (!uid) {
      return {
        success: false,
        queuedCount: 0,
        jobIds: [],
        error: "missing_user",
      };
    }

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
  },
);

exports.onBarcodeEnrichmentJobWritten = onDocumentWritten(
  {
    document: `${JOB_COLLECTION}/{jobId}`,
    region: FUNCTION_REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
    maxInstances: WORKER_MAX_INSTANCES,
    retry: false,
  },
  async (event) => {
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
  },
);

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
  const resolvedItemRef = itemRef ?? inventoryItemRef(uid, itemId);
  const itemSnapshot = await resolvedItemRef.get();
  if (!itemSnapshot.exists) {
    throw new Error("item_not_found");
  }

  const requestedAt = nowIso();
  const searchKeywords = buildKeywords({
    itemName,
    brand,
    storeName,
    weight,
    fingerprint,
  });
  const lookupKeywords = buildLookupKeywords({
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

  const cachedResolution = await resolveFromGlobalCatalog({
    fingerprint,
    itemName,
    brand,
    weight,
    lookupKeywords,
  });
  if (cachedResolution?.barcode) {
    const mergedCandidates = ensureCandidatesContainBarcode(
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
    await touchGlobalResolution(cachedResolution.matchedFingerprint);
    if (
      cachedResolution.matchedFingerprint !== fingerprint &&
      cachedResolution.matchType === "keyword" &&
      cachedResolution.score >= KEYWORD_ALIAS_MIN_SCORE
    ) {
      await upsertGlobalResolution({
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
    logger.info("Inventory item resolved from global cache.", {
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

  const candidates = await resolveCandidates({
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
    await upsertGlobalResolution({
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
    logger.info("Inventory item barcode resolved.", {
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
  logger.info("Inventory item barcode unresolved.", {
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

async function resolveCandidates({ itemName, brand, storeName, weight }) {
  const prompt = buildSinglePrompt({ itemName, brand, storeName, weight });
  logger.info("Barcode AI request payload.", {
    model: MODEL_NAME,
    location: MODEL_LOCATION,
    prompt: clipTextForLog(prompt),
  });

  const response = await ai.models.generateContent({
    model: MODEL_NAME,
    contents: prompt,
    config: {
      temperature: 0.1,
      maxOutputTokens: MAX_OUTPUT_TOKENS,
      responseMimeType: "application/json",
      thinkingConfig: {
        thinkingLevel: MODEL_THINKING_LEVEL,
      },
      tools: [{ googleSearch: {} }],
    },
  });

  const parsed = parseResponseAsJson(response);
  const rawCandidates = Array.isArray(parsed?.ean_candidates) ?
    parsed.ean_candidates :
    [];
  const candidates = normalizeCandidates(rawCandidates);
  const selectedBarcode = candidates.length > 0 ? candidates[0] : null;

  logger.info("Barcode AI response payload.", {
    model: MODEL_NAME,
    location: MODEL_LOCATION,
    responseText: clipTextForLog(extractTextResponse(response)),
    rawCandidates,
    candidates,
    selectedBarcode,
    found: selectedBarcode !== null,
  });

  return candidates;
}

function buildSinglePrompt({ itemName, brand, storeName, weight }) {
  const safeItemName = JSON.stringify(itemName);
  const safeBrand = JSON.stringify(brand ?? "unknown");
  const safeStoreName = JSON.stringify(storeName ?? "unknown");
  const safeWeight = JSON.stringify(weight ?? "unknown");
  return [
    "Du bist ein EAN-Resolver fuer Lebensmittel.",
    "Nutze Websuche aktiv.",
    "Gib nur JSON zurueck.",
    "",
    "Antwortformat:",
    "{",
    '  "ean_candidates": ["digits_only"]',
    "}",
    "",
    "Regeln:",
    "- Nur Ziffern mit 8 bis 14 Stellen.",
    "- Maximal 5 Kandidaten.",
    "- Wenn unsicher: leeres Array.",
    "",
    `item_name: ${safeItemName}`,
    `store_name: ${safeStoreName}`,
    `brand: ${safeBrand}`,
    `weight: ${safeWeight}`,
  ].join("\n");
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
      barcodeCandidates: ensureCandidatesContainBarcode(candidates, barcode),
      barcodeResolvedAt: nowIso(),
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
      barcodeCandidates: normalizeCandidates(candidates),
      barcodeLookupRequestedAt: requestedAt,
      foodFingerprint: fingerprint,
      searchKeywords,
    },
    { merge: true },
  );
}

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

  const bestMatch = rankedMatches[0];
  return bestMatch;
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
  };
}

function scoreKeywordMatch({
  data,
  itemName,
  brand,
  lookupKeywords,
}) {
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
  const tokenIntersectionCount = countSetIntersection(
    itemTokenSet,
    docTokenSet,
  );
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

async function lockQueuedJob(jobRef) {
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(jobRef);
    if (!snapshot.exists) {
      return { shouldProcess: false, attempts: 0 };
    }

    const data = snapshot.data() ?? {};
    const status = readString(data.status) ?? "queued";
    if (status !== "queued") {
      return { shouldProcess: false, attempts: readPositiveInt(data.attempts) };
    }

    const attempts = readPositiveInt(data.attempts) + 1;
    const updatedAt = nowIso();
    if (attempts > MAX_JOB_ATTEMPTS) {
      tx.set(
        jobRef,
        {
          status: "failed",
          attempts,
          updatedAt,
          completedAt: updatedAt,
          lastError: "max_attempts_exceeded",
        },
        { merge: true },
      );
      return { shouldProcess: false, attempts };
    }

    tx.set(
      jobRef,
      {
        status: "running",
        attempts,
        updatedAt,
        startedAt: updatedAt,
        lastError: null,
      },
      { merge: true },
    );
    return { shouldProcess: true, attempts };
  });
}

async function markJobDone({
  jobRef,
  attempts,
  fingerprint,
  found,
  barcode,
  candidates,
  source,
}) {
  const updatedAt = nowIso();
  await jobRef.set(
    {
      status: "done",
      attempts,
      updatedAt,
      completedAt: updatedAt,
      fingerprint,
      found,
      barcode: barcode ?? null,
      candidates: normalizeCandidates(candidates),
      source,
      lastError: null,
    },
    { merge: true },
  );
}

async function markJobNoResult({
  jobRef,
  attempts,
  fingerprint,
  candidates,
  source,
}) {
  const updatedAt = nowIso();
  const canRetry = attempts < MAX_JOB_ATTEMPTS;
  await jobRef.set(
    {
      status: canRetry ? "queued" : "done",
      attempts,
      updatedAt,
      completedAt: canRetry ? null : updatedAt,
      fingerprint,
      found: false,
      barcode: null,
      candidates: normalizeCandidates(candidates),
      source,
      lastError: canRetry ? "no_candidates_retrying" : "no_candidates",
    },
    { merge: true },
  );
}

async function markJobFailed({ jobRef, attempts, error }) {
  const updatedAt = nowIso();
  const canRetry = attempts < MAX_JOB_ATTEMPTS;
  await jobRef.set(
    {
      status: canRetry ? "queued" : "failed",
      attempts,
      updatedAt,
      completedAt: canRetry ? null : updatedAt,
      lastError: error,
    },
    { merge: true },
  );
}

async function markJobResourceExhausted({ jobRef, attempts, error }) {
  const updatedAt = nowIso();
  const normalizedAttempts = Math.max(0, attempts - 1);
  await jobRef.set(
    {
      status: "failed",
      attempts: normalizedAttempts,
      updatedAt,
      completedAt: updatedAt,
      lastError: error,
      errorCode: "resource_exhausted",
    },
    { merge: true },
  );
}

function normalizeEnqueueItems(rawItems) {
  const dedupedByItemId = new Map();
  for (const rawItem of rawItems) {
    if (dedupedByItemId.size >= MAX_ENQUEUE_ITEMS) {
      break;
    }

    const itemId = readString(rawItem?.itemId);
    const itemName = readString(rawItem?.itemName);
    if (!itemId || !itemName) {
      continue;
    }

    const brand = readString(rawItem?.brand);
    const storeName = readString(rawItem?.storeName);
    const weight = readString(rawItem?.weight);
    const fingerprint = readString(rawItem?.fingerprint) ??
      computeFoodFingerprint({ name: itemName, brand });

    dedupedByItemId.set(itemId, {
      itemId,
      itemName,
      brand,
      storeName,
      weight,
      fingerprint,
    });
  }
  return Array.from(dedupedByItemId.values());
}

function normalizeJob(data) {
  if (!data || typeof data !== "object") {
    return null;
  }
  const uid = readString(data.uid);
  const itemId = readString(data.itemId);
  const itemName = readString(data.itemName);
  const fingerprint = readString(data.fingerprint);
  if (!uid || !itemId || !itemName || !fingerprint) {
    return null;
  }
  return {
    uid,
    itemId,
    itemName,
    fingerprint,
    brand: readString(data.brand),
    storeName: readString(data.storeName),
    weight: readString(data.weight),
    trigger: readString(data.trigger) ?? "receipt_upload",
  };
}

function composeJobId(uid, itemId) {
  return Buffer.from(`${uid}::${itemId}`).toString("base64url");
}

function inventoryItemRef(uid, itemId) {
  return db
    .collection(USERS_COLLECTION)
    .doc(uid)
    .collection(INVENTORY_ITEMS_COLLECTION)
    .doc(itemId);
}

function globalResolutionRef(fingerprint) {
  return db.collection(GLOBAL_RESOLUTIONS_COLLECTION).doc(fingerprint);
}

function buildKeywords({ itemName, brand, storeName, weight, fingerprint }) {
  const sources = [
    itemName,
    brand,
    storeName,
    weight,
    fingerprint?.replace(/__/g, " ").replace(/_/g, " "),
  ];
  const keywords = new Set();
  for (const source of sources) {
    const normalized = normalizeForLookup(source);
    if (!normalized) {
      continue;
    }
    keywords.add(normalized);
    for (const token of normalized.split(" ")) {
      if (token.length >= 2) {
        keywords.add(token);
      }
    }
  }
  return Array.from(keywords).slice(0, 40);
}

function buildLookupKeywords({ itemName, brand, weight }) {
  const sources = [itemName, brand, weight];
  const keywords = new Set();
  for (const source of sources) {
    const normalized = normalizeForLookup(source);
    if (!normalized) {
      continue;
    }
    keywords.add(normalized);
    for (const token of tokenizeForLookup(normalized)) {
      keywords.add(token);
    }
  }
  return Array.from(keywords).slice(0, MAX_KEYWORD_QUERY_TERMS);
}

function tokenizeForLookup(value) {
  const normalized = normalizeForLookup(value);
  if (!normalized) {
    return [];
  }
  const tokens = normalized
    .split(" ")
    .map((token) => token.trim())
    .filter((token) => token.length >= 3)
    .filter((token) => !LOOKUP_STOPWORDS.has(token));

  const expanded = new Set();
  for (const token of tokens) {
    expanded.add(normalizeLookupToken(token));
    for (const splitToken of splitCompoundLookupToken(token)) {
      expanded.add(normalizeLookupToken(splitToken));
    }
  }
  return Array.from(expanded).filter((token) => {
    return token.length >= 3 && !LOOKUP_STOPWORDS.has(token);
  });
}

function normalizeLookupToken(token) {
  const normalized = normalizeForLookup(token);
  if (!normalized) {
    return "";
  }
  return LOOKUP_TOKEN_ALIASES.get(normalized) ?? normalized;
}

function splitCompoundLookupToken(token) {
  const normalized = normalizeForLookup(token);
  if (!normalized) {
    return [];
  }

  if (normalized.includes("haehnchenbrustfilet")) {
    return ["haehnchen", "brust", "filet"];
  }
  if (normalized.includes("haehnchenfilet")) {
    return ["haehnchen", "filet"];
  }
  if (normalized.includes("brustfilet")) {
    return ["brust", "filet"];
  }
  if (normalized.includes("thunfischfilet")) {
    return ["thunfisch", "filet"];
  }
  if (normalized.includes("sonnenblumenkerne")) {
    return ["sonnenblumen", "kerne"];
  }
  return [];
}

function normalizeForLookup(value) {
  const raw = readString(value);
  if (!raw) {
    return null;
  }
  const replacedUmlauts = raw
    .toLowerCase()
    .replace(/ä/g, "ae")
    .replace(/ö/g, "oe")
    .replace(/ü/g, "ue")
    .replace(/ß/g, "ss");
  const normalized = replacedUmlauts
    .replace(/[_\-]+/g, " ")
    .replace(/[^a-z0-9 ]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  return normalized.length > 0 ? normalized : null;
}

function parseResponseAsJson(response) {
  const directCandidates = response?.ean_candidates;
  if (Array.isArray(directCandidates)) {
    return { ean_candidates: directCandidates };
  }

  const text = extractTextResponse(response);
  if (!text) {
    return null;
  }

  const attempts = [text];
  const firstObject = text.indexOf("{");
  const lastObject = text.lastIndexOf("}");
  if (firstObject >= 0 && lastObject > firstObject) {
    attempts.push(text.slice(firstObject, lastObject + 1));
  }

  for (const candidate of attempts) {
    try {
      return JSON.parse(candidate);
    } catch (_) {
      continue;
    }
  }
  return null;
}

function extractTextResponse(response) {
  const textField = response?.text;
  if (typeof textField === "string") {
    return textField;
  }
  if (typeof textField === "function") {
    const textFromFn = readString(textField.call(response));
    if (textFromFn) {
      return textFromFn;
    }
  }

  const parts = response?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) {
    return null;
  }
  const joined = parts
    .map((part) => readString(part?.text))
    .filter(Boolean)
    .join("\n");
  return readString(joined);
}

function normalizeCandidates(rawCandidates) {
  const deduped = [];
  for (const rawCandidate of rawCandidates ?? []) {
    const normalized = normalizeBarcode(rawCandidate);
    if (!normalized || deduped.includes(normalized)) {
      continue;
    }
    deduped.push(normalized);
    if (deduped.length >= MAX_CANDIDATES_PER_ITEM) {
      break;
    }
  }
  return deduped;
}

function ensureCandidatesContainBarcode(candidates, barcode) {
  const normalizedBarcode = normalizeBarcode(barcode);
  if (!normalizedBarcode) {
    return normalizeCandidates(candidates);
  }

  const deduped = normalizeCandidates(candidates);
  if (!deduped.includes(normalizedBarcode)) {
    deduped.unshift(normalizedBarcode);
  }
  return deduped.slice(0, MAX_CANDIDATES_PER_ITEM);
}

function normalizeBarcode(value) {
  const raw = readString(value);
  if (!raw) {
    return null;
  }
  const digits = raw.replace(/\D+/g, "");
  if (digits.length < 8 || digits.length > 14) {
    return null;
  }
  return digits;
}

function computeFoodFingerprint({ name, brand }) {
  const safeName = slugify(name);
  const safeBrand = slugify(brand ?? "");
  if (!safeBrand) {
    return safeName || "unknown_food";
  }
  return `${safeName || "unknown"}__${safeBrand}`;
}

function slugify(value) {
  const raw = readString(value);
  if (!raw) {
    return "";
  }
  return raw
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function readString(value) {
  return typeof value === "string" && value.trim().length > 0 ?
    value.trim() :
    null;
}

function readPositiveInt(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) {
    return 0;
  }
  return Math.floor(parsed);
}

function nowIso() {
  return new Date().toISOString();
}

function extractErrorMessage(error) {
  if (error == null) {
    return "unknown_error";
  }
  if (typeof error === "string") {
    return error;
  }
  const message = readString(error?.message);
  const code = Number(error?.code);
  const details = readString(error?.details);

  const parts = [];
  if (Number.isFinite(code)) {
    parts.push(`code=${code}`);
  }
  if (message) {
    parts.push(`message=${message}`);
  }
  if (details) {
    parts.push(`details=${details}`);
  }
  return parts.length > 0 ? parts.join("; ") : "unknown_error";
}

function extractErrorDetails(error) {
  if (error == null || typeof error !== "object") {
    return null;
  }

  const cause = error.cause;
  return {
    name: readString(error.name),
    status: readString(error.status),
    code: Number.isFinite(Number(error.code)) ? Number(error.code) : null,
    stack: readString(error.stack),
    causeName: readString(cause?.name),
    causeStatus: readString(cause?.status),
    causeCode: Number.isFinite(Number(cause?.code)) ?
      Number(cause.code) :
      null,
    causeMessage: readString(cause?.message),
  };
}

function isResourceExhaustedError(error) {
  if (error == null || typeof error !== "object") {
    return false;
  }

  const code = Number(error.code);
  if (Number.isFinite(code) && code === 429) {
    return true;
  }

  const status = readString(error.status);
  if (status && status.toUpperCase().includes("RESOURCE_EXHAUSTED")) {
    return true;
  }

  const message = readString(error.message);
  if (message) {
    const upper = message.toUpperCase();
    if (upper.includes("RESOURCE_EXHAUSTED")) {
      return true;
    }
    if (upper.includes("429")) {
      return true;
    }
  }

  const cause = error.cause;
  const causeMessage = readString(cause?.message);
  if (causeMessage) {
    const upperCauseMessage = causeMessage.toUpperCase();
    if (
      upperCauseMessage.includes("RESOURCE_EXHAUSTED") ||
      upperCauseMessage.includes("429")
    ) {
      return true;
    }
  }

  return false;
}

function clipTextForLog(value, maxLength = 4000) {
  const text = readString(value);
  if (!text) {
    return null;
  }
  if (text.length <= maxLength) {
    return text;
  }
  return `${text.slice(0, maxLength)}...(truncated)`;
}
