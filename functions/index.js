const crypto = require("crypto");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { genkit, z } = require("genkit");
const { enableFirebaseTelemetry } = require("@genkit-ai/firebase");
const { vertexAI } = require("@genkit-ai/google-genai");
const admin = require("firebase-admin");

admin.initializeApp();

const telemetryOptIn =
  readString(process.env.ENABLE_GENKIT_FIREBASE_TELEMETRY) === "true";
const projectHint =
  readString(process.env.GCLOUD_PROJECT) ??
  readString(process.env.PROJECT_ID);
if (telemetryOptIn && projectHint) {
  enableFirebaseTelemetry().catch((error) => {
    logger.warn("Genkit Firebase telemetry initialization failed.", {
      error: error?.message ?? "unknown_error",
    });
  });
}

const db = admin.firestore();
const SERVER_TIMESTAMP = admin.firestore.FieldValue.serverTimestamp();

const FUNCTION_REGION = "europe-west1";
const USER_REQUEST_PATH =
  "users/{uid}/barcode_enrichment_requests/{fingerprint}";
const GLOBAL_JOB_PATH = "barcode_enrichment_jobs/{fingerprint}";

const RUNNER_LOCK_REF = db
  .collection("system_runtime")
  .doc("barcode_enrichment_runner_lock");
const RUNNER_LEASE_MS = 180000;
const RUNNER_MAX_CYCLES = 30;
const RUNNER_IDLE_WAIT_MS = 350;
const RUNNER_REQUIRED_EMPTY_CHECKS = 2;

const BARCODE_TEMPLATE_DEFAULT_MODEL = "gemini-3.1-pro-preview";

const barcodeTemplateModelParam = defineString("BARCODE_TEMPLATE_MODEL", {
  default: BARCODE_TEMPLATE_DEFAULT_MODEL,
});
const barcodeTemplateLocationParam = defineString(
  "BARCODE_TEMPLATE_LOCATION",
  { default: "global" },
);
const barcodeTemplateUseGoogleSearchParam = defineString(
  "BARCODE_TEMPLATE_USE_GOOGLE_SEARCH",
  { default: "true" },
);
const barcodeTemplateMaxOutputTokensParam = defineString(
  "BARCODE_TEMPLATE_MAX_OUTPUT_TOKENS",
  { default: "4096" },
);
const barcodeTemplateMaxBatchItemsParam = defineString(
  "BARCODE_TEMPLATE_MAX_BATCH_ITEMS",
  { default: "40" },
);
const barcodeTemplateMinCandidateCountParam = defineString(
  "BARCODE_TEMPLATE_MIN_CANDIDATES",
  { default: "1" },
);

const MAX_CANDIDATES_PER_ITEM = 5;
const DEFAULT_MAX_BATCH_ITEMS = 40;
const ABSOLUTE_MAX_BATCH_ITEMS = 64;
const DEFAULT_MAX_OUTPUT_TOKENS = 4096;
const MIN_MAX_OUTPUT_TOKENS = 512;
const MAX_MAX_OUTPUT_TOKENS = 8192;
const FIRESTORE_BATCH_MAX_WRITES = 450;
const MAX_JOB_ATTEMPTS = 3;

const ModelResultSchema = z.object({
  fingerprint: z.string().min(1),
  ean_candidates: z.array(z.string()).max(MAX_CANDIDATES_PER_ITEM),
});

const ModelBatchSchema = z.object({
  results: z.array(ModelResultSchema).max(ABSOLUTE_MAX_BATCH_ITEMS),
});

const aiRegistry = new Map();

exports.onBarcodeEnrichmentRequestWritten = onDocumentWritten(
  {
    document: USER_REQUEST_PATH,
    region: FUNCTION_REGION,
  },
  async (event) => {
    const beforeData = event.data?.before?.data() ?? null;
    const requestData = event.data?.after?.data();
    const uid = event.params.uid;
    const fingerprint = event.params.fingerprint;

    if (!requestData || !uid || !fingerprint) {
      return;
    }
    if (!shouldQueueFromRequestWrite({ beforeData, afterData: requestData })) {
      return;
    }

    const requestRef = db
      .collection("users")
      .doc(uid)
      .collection("barcode_enrichment_requests")
      .doc(fingerprint);
    const jobRef = db.collection("barcode_enrichment_jobs").doc(fingerprint);

    try {
      const queued = await upsertGlobalJobFromRequest({
        jobRef,
        requestData,
        uid,
        fingerprint,
      });
      await requestRef.set(
        {
          status: queued ? "queued" : "resolved",
          updated_at: SERVER_TIMESTAMP,
        },
        { merge: true },
      );
    } catch (error) {
      logger.error("Enqueue trigger failed", error, { fingerprint, uid });
      await requestRef.set(
        {
          status: "failed",
          error: extractErrorMessage(error),
          updated_at: SERVER_TIMESTAMP,
        },
        { merge: true },
      );
    }
  },
);

exports.onBarcodeEnrichmentJobWritten = onDocumentWritten(
  {
    document: GLOBAL_JOB_PATH,
    region: FUNCTION_REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (event) => {
    const jobData = event.data?.after?.data();
    if (!jobData || jobData.status !== "queued") {
      return;
    }

    const lockToken = crypto.randomUUID();
    const acquired = await acquireRunnerLock(lockToken);
    if (!acquired) {
      return;
    }

    try {
      await drainQueue(lockToken);
    } catch (error) {
      logger.error("Queue runner failed.", error, {
        error: extractErrorMessage(error),
      });
    } finally {
      await releaseRunnerLock(lockToken);
    }
  },
);

async function drainQueue(lockToken) {
  let emptyChecks = 0;
  for (let cycle = 0; cycle < RUNNER_MAX_CYCLES; cycle += 1) {
    const jobs = await loadAndMarkQueuedJobs();
    if (jobs.length === 0) {
      emptyChecks += 1;
      if (emptyChecks >= RUNNER_REQUIRED_EMPTY_CHECKS) {
        return;
      }
      await sleepMs(RUNNER_IDLE_WAIT_MS);
      await refreshRunnerLock(lockToken);
      continue;
    }
    emptyChecks = 0;

    try {
      await resolveAndPersistBatch(jobs);
    } catch (error) {
      logger.error("Batch resolution failed.", error, {
        batchSize: jobs.length,
      });
      await markBatchFailed(jobs, extractErrorMessage(error));
    }

    await refreshRunnerLock(lockToken);
  }

  logger.warn("Queue runner stopped at max cycles.", {
    maxCycles: RUNNER_MAX_CYCLES,
  });
}

async function loadAndMarkQueuedJobs() {
  const limit = resolveMaxBatchItems();
  const snapshot = await db
    .collection("barcode_enrichment_jobs")
    .where("status", "==", "queued")
    .limit(limit)
    .get();
  if (snapshot.empty) {
    return [];
  }

  const jobs = snapshot.docs.map((doc) => ({
    ref: doc.ref,
    fingerprint: doc.id,
    data: doc.data() ?? {},
    attempts: Number(doc.data()?.attempts ?? 0),
  }));

  const batch = db.batch();
  for (const job of jobs) {
    const attempts = Number(job.attempts ?? 0) + 1;
    job.attempts = attempts;
    batch.set(
      job.ref,
      {
        status: "processing",
        attempts,
        error: null,
        updated_at: SERVER_TIMESTAMP,
      },
      { merge: true },
    );
  }
  await batch.commit();
  return jobs;
}

async function resolveAndPersistBatch(jobs) {
  const modelItems = [];
  const resolvedByFingerprint = new Map();

  for (const job of jobs) {
    const provided = normalizeBarcode(job.data?.provided_barcode);
    if (provided) {
      resolvedByFingerprint.set(job.fingerprint, [provided]);
      continue;
    }
    modelItems.push(toPromptItem(job));
  }

  if (modelItems.length > 0) {
    const modelResults = await resolveBatchWithGemini(modelItems);
    for (const [fingerprint, candidates] of modelResults.entries()) {
      resolvedByFingerprint.set(fingerprint, candidates);
    }
  }

  const minCandidates = resolveMinCandidateCount();
  for (const job of jobs) {
    const requestUids = extractRequestUidsFromJob(job.data);
    const candidates = resolvedByFingerprint.get(job.fingerprint) ?? [];
    const topBarcode = candidates.length >= minCandidates ?
      candidates[0] :
      null;

    await persistFingerprintCandidates({
      fingerprint: job.fingerprint,
      candidates,
      topBarcode,
    });

    if (topBarcode) {
      await markResolved({
        jobRef: job.ref,
        fingerprint: job.fingerprint,
        requestUids,
        barcode: topBarcode,
        candidates,
      });
      continue;
    }

    await markNeedsUserBarcode({
      jobRef: job.ref,
      fingerprint: job.fingerprint,
      requestUids,
    });
  }
}

function toPromptItem(job) {
  return {
    fingerprint: job.fingerprint,
    itemName: readString(job.data?.item_name) ?? "unknown",
    brand: readString(job.data?.brand) ?? "unknown",
    storeName: readStoreName(job.data) ?? "unknown",
    weight: readItemWeightLabel(job.data) ?? "unknown",
  };
}

async function resolveBatchWithGemini(items) {
  const safeItems = Array.isArray(items) ? items : [];
  if (safeItems.length === 0) {
    return new Map();
  }

  const model = readString(barcodeTemplateModelParam.value()) ??
    BARCODE_TEMPLATE_DEFAULT_MODEL;
  const location = readString(barcodeTemplateLocationParam.value()) ?? "global";

  logger.info("Starting template batch model call.", {
    model,
    location,
    itemCount: safeItems.length,
  });

  const prompt = buildPrompt(safeItems);
  const results = await runModel({
    prompt,
    model,
    location,
  });

  logger.info("Template batch model call succeeded.", {
    model,
    location,
    itemCount: safeItems.length,
  });

  return normalizeModelResults({
    rawResults: results,
    fallbackItems: safeItems,
  });
}

async function runModel({ prompt, model, location }) {
  const useGoogleSearch =
    readString(barcodeTemplateUseGoogleSearchParam.value()) !== "false";
  const ai = getAi(location);
  let response = null;
  try {
    response = await ai.generate({
      model: vertexAI.model(model, { location }),
      prompt,
      config: {
        temperature: 0.1,
        maxOutputTokens: resolveMaxOutputTokens(),
        ...(useGoogleSearch ? { googleSearchRetrieval: true } : {}),
      },
      output: {
        schema: ModelBatchSchema,
        constrained: true,
      },
    });
  } catch (error) {
    const message = extractErrorMessage(error).toLowerCase();
    const retryWithoutSearch =
      useGoogleSearch &&
      (message.includes("invalid_argument") || message.includes("code=400"));
    if (!retryWithoutSearch) {
      throw error;
    }

    logger.warn("Retrying model call without google search retrieval.", {
      model,
      location,
      error: extractErrorMessage(error),
    });
    response = await ai.generate({
      model: vertexAI.model(model, { location }),
      prompt,
      config: {
        temperature: 0.1,
        maxOutputTokens: resolveMaxOutputTokens(),
      },
      output: {
        schema: ModelBatchSchema,
        constrained: true,
      },
    });
  }
  if (!response.output || !Array.isArray(response.output.results)) {
    throw new Error("template_empty_output");
  }
  return response.output.results;
}

function buildPrompt(items) {
  const lines = [];
  for (let i = 0; i < items.length; i += 1) {
    const item = items[i];
    const safeFingerprint = JSON.stringify(item.fingerprint);
    const safeItemName = JSON.stringify(item.itemName);
    const safeBrand = JSON.stringify(item.brand);
    const safeStoreName = JSON.stringify(item.storeName);
    const safeWeight = JSON.stringify(item.weight);
    lines.push(
      `${i + 1}. fingerprint=${safeFingerprint}; ` +
      `item_name=${safeItemName}; ` +
      `brand=${safeBrand}; ` +
      `store_name=${safeStoreName}; ` +
      `weight=${safeWeight}`,
    );
  }

  return [
    "Du bist ein EAN-Resolver für Lebensmittel.",
    "Nutze Websuche aktiv, um EAN-Kandidaten zu finden.",
    "Arbeite gründlich und priorisiere korrekte EANs.",
    "Antworte NUR als JSON.",
    "Ausgabeformat:",
    "{",
    "  \"results\": [",
    "    {",
    "      \"fingerprint\": \"string\",",
    "      \"ean_candidates\": [\"digits_only\"]",
    "    }",
    "  ]",
    "}",
    "Regeln:",
    "- Nur Ziffern mit 8 bis 14 Stellen.",
    "- Keine zusätzlichen Felder.",
    "- Genau ein result pro Input-Item.",
    "- Gleiche Reihenfolge wie Input.",
    "- Wenn unklar: ean_candidates=[]",
    "",
    "items:",
    ...lines,
  ].join("\n");
}

function normalizeModelResults({ rawResults, fallbackItems }) {
  const normalized = new Map();
  const safeResults = Array.isArray(rawResults) ? rawResults : [];
  const safeFallbackItems = Array.isArray(fallbackItems) ? fallbackItems : [];

  for (let i = 0; i < safeResults.length; i += 1) {
    const raw = safeResults[i];
    const fingerprint = readString(raw?.fingerprint) ??
      readString(safeFallbackItems[i]?.fingerprint);
    if (!fingerprint) {
      continue;
    }
    if (normalized.has(fingerprint)) {
      continue;
    }

    const candidates = normalizeCandidateList(raw?.ean_candidates);
    normalized.set(fingerprint, candidates);
  }

  for (const item of safeFallbackItems) {
    const fingerprint = readString(item?.fingerprint);
    if (!fingerprint || normalized.has(fingerprint)) {
      continue;
    }
    normalized.set(fingerprint, []);
  }

  return normalized;
}

function normalizeCandidateList(input) {
  if (!Array.isArray(input)) {
    return [];
  }
  const deduped = [];
  for (const raw of input) {
    const barcode = normalizeBarcode(raw);
    if (!barcode || deduped.includes(barcode)) {
      continue;
    }
    deduped.push(barcode);
    if (deduped.length >= MAX_CANDIDATES_PER_ITEM) {
      break;
    }
  }
  return deduped;
}

async function persistFingerprintCandidates({
  fingerprint,
  candidates,
  topBarcode,
}) {
  const ref = db.collection("food_fingerprint_catalog").doc(fingerprint);
  await ref.set(
    {
      fingerprint,
      barcode: topBarcode,
      ean_candidates: Array.isArray(candidates) ? candidates : [],
      updated_at: SERVER_TIMESTAMP,
      resolved_at: topBarcode ? SERVER_TIMESTAMP : null,
    },
    { merge: true },
  );
}

async function markResolved({
  jobRef,
  fingerprint,
  requestUids,
  barcode,
  candidates,
}) {
  await Promise.all([
    jobRef.set(
      {
        status: "resolved",
        barcode,
        error: null,
        resolved_at: SERVER_TIMESTAMP,
        updated_at: SERVER_TIMESTAMP,
      },
      { merge: true },
    ),
    patchUserRequestsByFingerprint({
      fingerprint,
      requestUids,
      patch: {
        status: "resolved",
        error: null,
        barcode,
        resolved_barcode: barcode,
        ean_candidates: Array.isArray(candidates) ? candidates : [],
        updated_at: SERVER_TIMESTAMP,
      },
    }),
  ]);
}

async function markNeedsUserBarcode({
  jobRef,
  fingerprint,
  requestUids,
}) {
  await Promise.all([
    jobRef.set(
      {
        status: "needs_user_barcode",
        error: "no_candidate",
        updated_at: SERVER_TIMESTAMP,
      },
      { merge: true },
    ),
    patchUserRequestsByFingerprint({
      fingerprint,
      requestUids,
      patch: {
        status: "needs_user_barcode",
        error: "no_candidate",
        updated_at: SERVER_TIMESTAMP,
      },
    }),
  ]);
}

async function markBatchFailed(jobs, errorMessage) {
  for (const job of jobs) {
    const attempts = Number(job.attempts ?? job.data?.attempts ?? 0);
    const shouldRetry = attempts < MAX_JOB_ATTEMPTS;
    const nextStatus = shouldRetry ? "queued" : "failed";
    await job.ref.set(
      {
        status: nextStatus,
        error: errorMessage,
        updated_at: SERVER_TIMESTAMP,
      },
      { merge: true },
    );

    if (shouldRetry) {
      continue;
    }

    const requestUids = extractRequestUidsFromJob(job.data);
    await patchUserRequestsByFingerprint({
      fingerprint: job.fingerprint,
      requestUids,
      patch: {
        status: nextStatus,
        error: errorMessage,
        updated_at: SERVER_TIMESTAMP,
      },
    });
  }
}

async function patchUserRequestsByFingerprint({
  fingerprint,
  requestUids,
  patch,
}) {
  const resolvedUids = extractRequestUids(requestUids);
  if (resolvedUids.length === 0) {
    return;
  }

  for (let i = 0; i < resolvedUids.length; i += FIRESTORE_BATCH_MAX_WRITES) {
    const chunk = resolvedUids.slice(i, i + FIRESTORE_BATCH_MAX_WRITES);
    const batch = db.batch();
    for (const uid of chunk) {
      const ref = db
        .collection("users")
        .doc(uid)
        .collection("barcode_enrichment_requests")
        .doc(fingerprint);
      batch.set(ref, patch, { merge: true });
    }
    await batch.commit();
  }
}

async function upsertGlobalJobFromRequest({
  jobRef,
  requestData,
  uid,
  fingerprint,
}) {
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(jobRef);
    const current = snapshot.exists ? snapshot.data() : null;

    const requestStatus = readString(requestData.status);
    const providedBarcode = normalizeBarcode(requestData.provided_barcode);
    const forceRetry = requestData.force_retry === true;
    const shouldQueue =
      requestStatus === "queued" ||
      providedBarcode != null ||
      forceRetry;

    tx.set(
      jobRef,
      {
        fingerprint,
        item_name: readString(requestData.item_name) ?? "unknown",
        brand: readString(requestData.brand),
        store_name: readStoreName(requestData),
        item_weight: readItemWeightLabel(requestData),
        provided_barcode: providedBarcode,
        priority: readString(requestData.priority) ?? "normal",
        trigger: readString(requestData.trigger) ?? "unknown",
        request_uids: admin.firestore.FieldValue.arrayUnion(uid),
        last_request_uid: uid,
        status: shouldQueue ? "queued" : (current?.status ?? "resolved"),
        error: shouldQueue ? null : current?.error ?? null,
        queued_at: shouldQueue ? SERVER_TIMESTAMP : current?.queued_at ?? null,
        updated_at: SERVER_TIMESTAMP,
      },
      { merge: true },
    );

    return shouldQueue;
  });
}

function shouldQueueFromRequestWrite({ beforeData, afterData }) {
  const nextStatus = readString(afterData.status);
  const previousStatus = readString(beforeData?.status);

  const nextProvided = normalizeBarcode(afterData.provided_barcode);
  const previousProvided = normalizeBarcode(beforeData?.provided_barcode);

  const forceRetryNow = afterData.force_retry === true;
  const forceRetryBefore = beforeData?.force_retry === true;
  const forceRetryBecameTrue = forceRetryNow && !forceRetryBefore;

  if (!beforeData) {
    return nextStatus === "queued" || nextProvided != null || forceRetryNow;
  }
  if (forceRetryBecameTrue) {
    return true;
  }
  if (nextProvided !== previousProvided && nextProvided != null) {
    return true;
  }
  return nextStatus === "queued" && previousStatus !== "queued";
}

async function acquireRunnerLock(lockToken) {
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(RUNNER_LOCK_REF);
    const current = snapshot.exists ? snapshot.data() : null;

    const owner = readString(current?.owner);
    const expiresAtMs = Number(current?.expires_at_ms ?? 0);
    const nowMs = Date.now();

    const lockActive = owner != null && expiresAtMs > nowMs;
    if (lockActive && owner !== lockToken) {
      return false;
    }

    tx.set(
      RUNNER_LOCK_REF,
      {
        owner: lockToken,
        expires_at_ms: nowMs + RUNNER_LEASE_MS,
        updated_at: SERVER_TIMESTAMP,
      },
      { merge: true },
    );
    return true;
  });
}

async function refreshRunnerLock(lockToken) {
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(RUNNER_LOCK_REF);
    const owner = readString(snapshot.data()?.owner);
    if (owner !== lockToken) {
      throw new Error("runner_lock_lost");
    }

    tx.set(
      RUNNER_LOCK_REF,
      {
        expires_at_ms: Date.now() + RUNNER_LEASE_MS,
        updated_at: SERVER_TIMESTAMP,
      },
      { merge: true },
    );
    return true;
  });
}

async function releaseRunnerLock(lockToken) {
  try {
    await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(RUNNER_LOCK_REF);
      const owner = readString(snapshot.data()?.owner);
      if (owner !== lockToken) {
        return false;
      }

      tx.set(
        RUNNER_LOCK_REF,
        {
          owner: null,
          expires_at_ms: 0,
          updated_at: SERVER_TIMESTAMP,
        },
        { merge: true },
      );
      return true;
    });
  } catch (error) {
    logger.warn("Failed to release queue runner lock.", {
      error: extractErrorMessage(error),
    });
  }
}

function getAi(location) {
  const projectId = process.env.GCLOUD_PROJECT ?? process.env.PROJECT_ID;
  const normalizedLocation = readString(location) ?? "global";
  const key = `${projectId ?? "unknown"}:${normalizedLocation}`;

  const cached = aiRegistry.get(key);
  if (cached) {
    return cached;
  }

  const ai = genkit({
    plugins: [
      vertexAI({
        projectId,
        location: normalizedLocation,
      }),
    ],
  });
  aiRegistry.set(key, ai);
  return ai;
}

function resolveMaxBatchItems() {
  const parsed = Math.floor(
    readNumber(barcodeTemplateMaxBatchItemsParam.value()),
  );
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_MAX_BATCH_ITEMS;
  }
  return Math.min(parsed, ABSOLUTE_MAX_BATCH_ITEMS);
}

function resolveMaxOutputTokens() {
  const parsed = Math.floor(
    readNumber(barcodeTemplateMaxOutputTokensParam.value()),
  );
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_MAX_OUTPUT_TOKENS;
  }
  const atLeastMin = Math.max(parsed, MIN_MAX_OUTPUT_TOKENS);
  return Math.min(atLeastMin, MAX_MAX_OUTPUT_TOKENS);
}

function resolveMinCandidateCount() {
  const parsed = Math.floor(
    readNumber(barcodeTemplateMinCandidateCountParam.value()),
  );
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return 1;
  }
  return Math.min(parsed, MAX_CANDIDATES_PER_ITEM);
}

function readStoreName(input) {
  if (!input || typeof input !== "object") {
    return null;
  }
  const candidates = [
    input.store_name,
    input.storeName,
    input.shop_name,
    input.shopName,
    input.retailer,
  ];
  for (const candidate of candidates) {
    const value = readString(candidate);
    if (value) {
      return value;
    }
  }
  return null;
}

function readItemWeightLabel(input) {
  if (!input || typeof input !== "object") {
    return null;
  }
  const candidates = [
    input.item_weight,
    input.itemWeight,
    input.weight_label,
    input.weightLabel,
    input.weight,
    input.package_size,
    input.packageSize,
  ];
  for (const candidate of candidates) {
    const value = readString(candidate);
    if (value) {
      return value;
    }
  }
  return null;
}

function extractRequestUidsFromJob(jobData) {
  return extractRequestUids([
    ...(Array.isArray(jobData?.request_uids) ? jobData.request_uids : []),
    jobData?.last_request_uid,
  ]);
}

function extractRequestUids(input) {
  const deduped = [];
  if (!Array.isArray(input)) {
    return deduped;
  }
  for (const value of input) {
    const uid = readString(value);
    if (!uid || deduped.includes(uid)) {
      continue;
    }
    deduped.push(uid);
  }
  return deduped;
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

function readString(value) {
  return typeof value === "string" && value.trim().length > 0 ?
    value.trim() :
    null;
}

function readNumber(value) {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

async function sleepMs(delayMs) {
  await new Promise((resolve) => setTimeout(resolve, delayMs));
}
