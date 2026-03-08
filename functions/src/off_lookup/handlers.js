const logger = require("firebase-functions/logger");
const { HttpsError } = require("firebase-functions/v2/https");
const { Timestamp } = require("firebase-admin/firestore");

const {
  db,
  FUNCTION_REGION,
  FieldValue,
} = require("../barcode_enrichment/runtime");
const { resolveRequestUid } = require("../barcode_enrichment/auth");
const {
  readString,
  normalizeBarcode,
  extractErrorMessage,
  extractErrorDetails,
} = require("../barcode_enrichment/helpers");

const OFF_BASE_HOST = "world.openfoodfacts.org";
const OFF_BASE_URL = `https://${OFF_BASE_HOST}`;
const OFF_CACHE_COLLECTION = "off_products";
const OFF_RATE_LIMIT_COLLECTION = "off_rate_limits";
const OFF_PRODUCT_GATE_DOC = "product_lookup";
const OFF_PRODUCT_MIN_INTERVAL_MS = readPositiveIntFromEnv(
  "OFF_PRODUCT_MIN_INTERVAL_MS",
  700,
);
const OFF_REQUEST_TIMEOUT_MS = readPositiveIntFromEnv(
  "OFF_REQUEST_TIMEOUT_MS",
  12000,
);
const OFF_RETRY_REQUEST_TIMEOUT_MS = readPositiveIntFromEnv(
  "OFF_RETRY_REQUEST_TIMEOUT_MS",
  5000,
);
const OFF_RETRY_DELAY_MS = readPositiveIntFromEnv(
  "OFF_RETRY_DELAY_MS",
  300,
);
const OFF_FOUND_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const OFF_NOT_FOUND_TTL_MS = 12 * 60 * 60 * 1000;

const OFF_CALLABLE_NAME = "resolveOffProductByBarcode";
const OFF_USER_AGENT = "YAMT/1.0 (repin@mailbox.org)";
const OFF_FIELDS =
  "_id,code,product_name,brands,nutriments,status," +
  "image_front_small_url,image_front_url,image_url,selected_images";

const LOOKUP_ERROR_INVALID_BARCODE = "invalid_barcode";
const LOOKUP_ERROR_REQUEST_FAILED = "off_request_failed";

const CACHE_STATUS_FOUND = "found";
const CACHE_STATUS_NOT_FOUND = "not_found";

function readPositiveIntFromEnv(key, fallback) {
  const raw = process.env[key];
  if (typeof raw !== "string" || raw.trim().length === 0) {
    return fallback;
  }

  const parsed = Number(raw);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return fallback;
  }
  return Math.floor(parsed);
}

function createOffLookupHandlers({
  functionRegion = FUNCTION_REGION,
  dbClient = db,
  loggerValue = logger,
  httpsErrorClass = HttpsError,
  resolveRequestUidValue = resolveRequestUid,
  readStringValue = readString,
  normalizeBarcodeValue = normalizeBarcode,
  nowMsValue = () => Date.now(),
  acquireOffProductSlotValue = acquireOffProductSlot,
  readCacheEntryValue = readCacheEntry,
  writeCacheEntryValue = writeCacheEntry,
  fetchOffProductValue = fetchOffProduct,
  buildLookupResponseValue = buildLookupResponse,
  extractErrorMessageValue = extractErrorMessage,
  extractErrorDetailsValue = extractErrorDetails,
} = {}) {
  const resolveOffProductByBarcodeOptions = {
    region: functionRegion,
    timeoutSeconds: 60,
    memory: "256MiB",
    enforceAppCheck: false,
  };

  async function resolveOffProductByBarcodeHandler(request) {
    const uid = resolveRequestUidValue(request, OFF_CALLABLE_NAME);
    const rawBarcode = readStringValue(request?.data?.barcode);
    const barcode = normalizeBarcodeValue(rawBarcode);

    if (!isSupportedBarcode(barcode)) {
      return {
        success: false,
        found: false,
        fromCache: false,
        error: LOOKUP_ERROR_INVALID_BARCODE,
      };
    }

    const nowMs = nowMsValue();
    const cached = await readCacheEntryValue({
      dbClient,
      cacheCollection: OFF_CACHE_COLLECTION,
      barcode,
      nowMs,
    });

    if (cached?.isFresh) {
      return buildLookupResponseValue({
        cached,
        fromCache: true,
        stale: false,
      });
    }

    try {
      const scheduledAtMs = await acquireOffProductSlotValue({
        dbClient,
        collection: OFF_RATE_LIMIT_COLLECTION,
        documentId: OFF_PRODUCT_GATE_DOC,
        minIntervalMs: OFF_PRODUCT_MIN_INTERVAL_MS,
        nowMs: nowMsValue(),
      });
      await waitUntil(scheduledAtMs, nowMsValue);

      const fetched = await fetchOffProductValue({
        barcode,
        timeoutMs: OFF_REQUEST_TIMEOUT_MS,
      });

      await writeCacheEntryValue({
        dbClient,
        cacheCollection: OFF_CACHE_COLLECTION,
        barcode,
        status: fetched.status,
        product: fetched.product,
        nowMs: nowMsValue(),
      });

      if (fetched.status === CACHE_STATUS_FOUND && fetched.product) {
        return {
          success: true,
          found: true,
          fromCache: false,
          stale: false,
          product: fetched.product,
        };
      }

      return {
        success: true,
        found: false,
        fromCache: false,
        stale: false,
      };
    } catch (error) {
      if (error instanceof httpsErrorClass) {
        throw error;
      }

      loggerValue.error("OFF backend lookup failed.", {
        uid,
        barcode,
        error: extractErrorMessageValue(error),
        details: extractErrorDetailsValue(error),
      });

      if (cached) {
        return buildLookupResponseValue({
          cached,
          fromCache: true,
          stale: true,
        });
      }

      return {
        success: false,
        found: false,
        fromCache: false,
        error: LOOKUP_ERROR_REQUEST_FAILED,
      };
    }
  }

  return {
    resolveOffProductByBarcodeOptions,
    resolveOffProductByBarcodeHandler,
  };
}

function isSupportedBarcode(barcode) {
  return typeof barcode === "string" && /^\d{8,14}$/.test(barcode);
}

function buildLookupResponse({ cached, fromCache, stale }) {
  if (!cached || cached.status === CACHE_STATUS_NOT_FOUND) {
    return {
      success: true,
      found: false,
      fromCache,
      stale,
    };
  }

  if (cached.status === CACHE_STATUS_FOUND && cached.product) {
    return {
      success: true,
      found: true,
      fromCache,
      stale,
      product: cached.product,
    };
  }

  return {
    success: true,
    found: false,
    fromCache,
    stale,
  };
}

async function readCacheEntry({
  dbClient,
  cacheCollection,
  barcode,
  nowMs,
}) {
  const snapshot = await dbClient.collection(cacheCollection).doc(barcode).get();
  if (!snapshot.exists) {
    return null;
  }

  const data = snapshot.data() ?? {};
  const status = readString(data.status);
  if (!status) {
    return null;
  }

  const expiresAtMs = readTimestampMs(data.expires_at);
  const isFresh = Number.isFinite(expiresAtMs) && expiresAtMs > nowMs;

  if (status === CACHE_STATUS_NOT_FOUND) {
    return {
      status,
      isFresh,
      product: null,
    };
  }

  if (status !== CACHE_STATUS_FOUND) {
    return null;
  }

  const product = normalizeStringKeyMap(data.product);
  if (!product) {
    return null;
  }

  return {
    status,
    isFresh,
    product,
  };
}

async function writeCacheEntry({
  dbClient,
  cacheCollection,
  barcode,
  status,
  product,
  nowMs,
}) {
  const document = dbClient.collection(cacheCollection).doc(barcode);
  const ttlMs = status === CACHE_STATUS_FOUND ? OFF_FOUND_TTL_MS :
    OFF_NOT_FOUND_TTL_MS;

  const payload = {
    barcode,
    status,
    product: status === CACHE_STATUS_FOUND ? product : null,
    source: "open_food_facts",
    fetched_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
    expires_at: Timestamp.fromMillis(nowMs + ttlMs),
  };

  await document.set(payload, { merge: true });
}

async function acquireOffProductSlot({
  dbClient,
  collection,
  documentId,
  minIntervalMs,
  nowMs,
}) {
  return acquireRateLimitSlot({
    dbClient,
    collection,
    documentId,
    minIntervalMs,
    nowMs,
  });
}

async function acquireRateLimitSlot({
  dbClient,
  collection,
  documentId,
  minIntervalMs,
  nowMs,
}) {
  const gateRef = dbClient.collection(collection).doc(documentId);
  const slotMs = await dbClient.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(gateRef);
    const data = snapshot.exists ? snapshot.data() ?? {} : {};

    const nextAllowedAtMs = readTimestampMs(data.next_allowed_at) ?? 0;
    const reservedAtMs = Math.max(nowMs, nextAllowedAtMs);
    const nextAtMs = reservedAtMs + minIntervalMs;

    transaction.set(gateRef, {
      next_allowed_at: Timestamp.fromMillis(nextAtMs),
      updated_at: FieldValue.serverTimestamp(),
    }, { merge: true });

    return reservedAtMs;
  });

  return slotMs;
}

async function waitUntil(targetMs, nowMsValue) {
  const waitMs = targetMs - nowMsValue();
  if (waitMs <= 0) {
    return;
  }
  await delay(waitMs);
}

function delay(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function fetchOffProduct({ barcode, timeoutMs }) {
  try {
    return await fetchOffProductOnce({
      barcode,
      timeoutMs,
    });
  } catch (error) {
    if (!isRetriableOffRequestError(error)) {
      throw error;
    }
    await delay(OFF_RETRY_DELAY_MS);
    return fetchOffProductOnce({
      barcode,
      timeoutMs: OFF_RETRY_REQUEST_TIMEOUT_MS,
    });
  }
}

async function fetchOffProductOnce({ barcode, timeoutMs }) {
  const url = new URL(`${OFF_BASE_URL}/api/v2/product/${barcode}.json`);
  url.searchParams.set("fields", OFF_FIELDS);

  const payload = await fetchJsonWithTimeout({
    url: url.toString(),
    timeoutMs,
    headers: {
      "User-Agent": OFF_USER_AGENT,
      "Accept": "application/json",
    },
  });

  if (!payload || typeof payload !== "object") {
    return {
      status: CACHE_STATUS_NOT_FOUND,
      product: null,
    };
  }

  const status = Number(payload.status);
  if (Number.isFinite(status) && status === 0) {
    return {
      status: CACHE_STATUS_NOT_FOUND,
      product: null,
    };
  }

  const product = normalizeStringKeyMap(payload.product);
  if (!product) {
    return {
      status: CACHE_STATUS_NOT_FOUND,
      product: null,
    };
  }

  const profile = buildProfileFromOffProduct({
    barcode,
    product,
    nowMs: Date.now(),
  });

  if (!profile) {
    return {
      status: CACHE_STATUS_NOT_FOUND,
      product: null,
    };
  }

  return {
    status: CACHE_STATUS_FOUND,
    product: profile,
  };
}

function isRetriableOffRequestError(error) {
  if (!error || typeof error !== "object") {
    return false;
  }

  const errorCode = Number(error.code);
  if (Number.isFinite(errorCode) && errorCode === 20) {
    return true;
  }

  const errorName = readString(error.name)?.toLowerCase();
  if (errorName === "aborterror") {
    return true;
  }

  const errorMessage = readString(error.message)?.toLowerCase() ?? "";
  if (errorMessage.includes("off_http_429")) {
    return true;
  }
  if (/off_http_5\d\d/.test(errorMessage)) {
    return true;
  }
  if (isTransientNetworkText(errorMessage)) {
    return true;
  }

  const causeMessage = readString(error?.cause?.message)?.toLowerCase() ?? "";
  if (isTransientNetworkText(causeMessage)) {
    return true;
  }

  return false;
}

function isTransientNetworkText(message) {
  if (!message) {
    return false;
  }
  return (
    message.includes("aborted") ||
    message.includes("connection closed") ||
    message.includes("timed out") ||
    message.includes("timeout") ||
    message.includes("econnreset") ||
    message.includes("fetch failed") ||
    message.includes("socket")
  );
}

async function fetchJsonWithTimeout({ url, timeoutMs, headers }) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, {
      method: "GET",
      headers,
      signal: controller.signal,
    });

    if (response.status === 404) {
      return null;
    }

    if (response.status !== 200) {
      throw new Error(`off_http_${response.status}`);
    }

    return response.json();
  } finally {
    clearTimeout(timeout);
  }
}

function buildProfileFromOffProduct({ barcode, product, nowMs }) {
  const name = readString(product.product_name)?.trim() ?? "";
  const brand = readString(product.brands)?.trim();
  const offProductId = readString(product._id);
  const imageUrl = resolveImageUrl(product);

  const nutriments = normalizeStringKeyMap(product.nutriments) ?? {};

  const per100Kcal = readDouble(
    nutriments["energy-kcal_100g"] ?? nutriments["energy-kcal_100ml"],
  );
  const per100Protein = readDouble(
    nutriments.proteins_100g ?? nutriments.proteins_100ml,
  );
  const per100Carbs = readDouble(
    nutriments.carbohydrates_100g ?? nutriments.carbohydrates_100ml,
  );
  const per100Fat = readDouble(
    nutriments.fat_100g ?? nutriments.fat_100ml,
  );

  if (name.isEmpty && per100Kcal <= 0 && imageUrl == null) {
    return null;
  }

  const nowIso = new Date(nowMs).toISOString();
  return {
    barcode,
    name: name.isEmpty ? barcode : name,
    brand: brand && brand.length > 0 ? brand : null,
    per100_kcal: per100Kcal,
    per100_protein: per100Protein,
    per100_carbs: per100Carbs,
    per100_fat: per100Fat,
    source: "off_barcode",
    off_product_id: offProductId,
    image_url: imageUrl,
    created_at: nowIso,
    updated_at: nowIso,
  };
}

function resolveImageUrl(product) {
  const direct = readString(product.image_front_small_url) ??
    readString(product.image_front_url) ??
    readString(product.image_url);
  const normalizedDirect = normalizeOffImageUrl(direct);
  if (normalizedDirect) {
    return normalizedDirect;
  }

  const selectedImages = normalizeStringKeyMap(product.selected_images);
  const front = normalizeStringKeyMap(selectedImages?.front);
  const display = normalizeStringKeyMap(front?.display);
  if (!display) {
    return null;
  }

  for (const value of Object.values(display)) {
    const normalized = normalizeOffImageUrl(value);
    if (normalized) {
      return normalized;
    }
  }

  return null;
}

function normalizeOffImageUrl(value) {
  const raw = readString(value)?.trim();
  if (!raw) {
    return null;
  }

  if (raw.startsWith("https://") || raw.startsWith("http://")) {
    return raw;
  }

  if (raw.startsWith("//")) {
    return `https:${raw}`;
  }

  if (raw.startsWith("/")) {
    return `https://${OFF_BASE_HOST}${raw}`;
  }

  return null;
}

function normalizeStringKeyMap(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }

  const entries = Object.entries(value);
  const normalized = {};
  for (const [key, nestedValue] of entries) {
    normalized[String(key)] = nestedValue;
  }
  return normalized;
}

function readTimestampMs(value) {
  if (!value) {
    return null;
  }

  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }

  if (value instanceof Date) {
    return value.getTime();
  }

  if (Number.isFinite(Number(value))) {
    return Number(value);
  }

  return null;
}

function readDouble(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Number.parseFloat(value.replaceAll(",", ".").trim());
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return 0;
}

const defaultOffLookupHandlers = createOffLookupHandlers();

module.exports = {
  createOffLookupHandlers,
  ...defaultOffLookupHandlers,
  CACHE_STATUS_FOUND,
  CACHE_STATUS_NOT_FOUND,
  isRetriableOffRequestError,
};
