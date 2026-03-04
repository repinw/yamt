const { onCall } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const { GoogleGenAI } = require("@google/genai");
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
const MAX_OUTPUT_TOKENS = 2048;
const MAX_CANDIDATES_PER_ITEM = 5;
const MAX_ENQUEUE_ITEMS = 40;
const MAX_JOB_RETRIES = 2;
const MAX_JOB_ATTEMPTS = MAX_JOB_RETRIES + 1;
const WORKER_MAX_INSTANCES = 7;

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
    timeoutSeconds: 60,
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
    const batch = db.batch();
    const jobIds = [];

    for (const item of items) {
      const jobId = composeJobId(uid, item.itemId);
      const jobRef = db.collection(JOB_COLLECTION).doc(jobId);
      batch.set(
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
          keywords: buildKeywords({
            itemName: item.itemName,
            brand: item.brand,
            storeName: item.storeName,
            weight: item.weight,
            fingerprint: item.fingerprint,
          }),
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

    await batch.commit();
    logger.info("Enqueued inventory barcode jobs.", {
      uid,
      trigger,
      queuedCount: jobIds.length,
    });

    return {
      success: true,
      queuedCount: jobIds.length,
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

  await resolvedItemRef.set(
    {
      foodFingerprint: fingerprint,
      barcodeLookupRequestedAt: requestedAt,
      searchKeywords,
    },
    { merge: true },
  );

  const cachedResolution = await readGlobalResolution(fingerprint);
  if (cachedResolution?.barcode) {
    const candidates = normalizeCandidates(cachedResolution.barcodeCandidates);
    const mergedCandidates = ensureCandidatesContainBarcode(
      candidates,
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
    await touchGlobalResolution(fingerprint);
    logger.info("Inventory item resolved from global cache.", {
      uid,
      itemId,
      fingerprint,
      barcode: cachedResolution.barcode,
      trigger,
    });
    return {
      found: true,
      barcode: cachedResolution.barcode,
      candidates: mergedCandidates,
      source: "global_cache",
    };
  }

  const candidates = await resolveCandidates({
    itemName,
    brand,
    fingerprint,
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

async function resolveCandidates({ itemName, brand, fingerprint }) {
  const prompt = buildSinglePrompt({ itemName, brand, fingerprint });
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

function buildSinglePrompt({ itemName, brand, fingerprint }) {
  const safeItemName = JSON.stringify(itemName);
  const safeBrand = JSON.stringify(brand ?? "unknown");
  const safeFingerprint = JSON.stringify(fingerprint);
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
    `fingerprint: ${safeFingerprint}`,
    `item_name: ${safeItemName}`,
    `brand: ${safeBrand}`,
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

async function readGlobalResolution(fingerprint) {
  const snapshot = await globalResolutionRef(fingerprint).get();
  if (!snapshot.exists) {
    return null;
  }
  const data = snapshot.data() ?? {};
  const barcode = normalizeBarcode(data.barcode);
  const barcodeCandidates = normalizeCandidates(data.barcodeCandidates);
  if (!barcode) {
    return null;
  }
  return {
    barcode,
    barcodeCandidates,
  };
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
      lastResolvedBy: uid,
      hitCount: FieldValue.increment(1),
      updatedAt: nowIso(),
    },
    { merge: true },
  );
}

async function touchGlobalResolution(fingerprint) {
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
