const {
  db,
  USERS_COLLECTION,
  INVENTORY_ITEMS_COLLECTION,
  GLOBAL_RESOLUTIONS_COLLECTION,
  MAX_CANDIDATES_PER_ITEM,
  MAX_ENQUEUE_ITEMS,
  MAX_KEYWORD_QUERY_TERMS,
  LOOKUP_STOPWORDS,
  LOOKUP_TOKEN_ALIASES,
} = require("./runtime");

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

function computeFoodFingerprint({ name, brand }) {
  const safeName = slugify(name);
  const safeBrand = slugify(brand ?? "");
  if (!safeBrand) {
    return safeName || "unknown_food";
  }
  return `${safeName || "unknown"}__${safeBrand}`;
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

function parseResponseAsJson(response) {
  const directCandidates = response?.ean_candidates;
  if (Array.isArray(directCandidates)) {
    const payload = {
      ean_candidates: directCandidates,
    };
    if (Object.prototype.hasOwnProperty.call(response, "is_uncertain")) {
      payload.is_uncertain = response.is_uncertain;
    }
    return payload;
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

module.exports = {
  readString,
  readPositiveInt,
  nowIso,
  normalizeBarcode,
  normalizeCandidates,
  ensureCandidatesContainBarcode,
  slugify,
  computeFoodFingerprint,
  normalizeForLookup,
  normalizeLookupToken,
  splitCompoundLookupToken,
  tokenizeForLookup,
  buildKeywords,
  buildLookupKeywords,
  composeJobId,
  inventoryItemRef,
  globalResolutionRef,
  normalizeEnqueueItems,
  normalizeJob,
  extractTextResponse,
  parseResponseAsJson,
  extractErrorMessage,
  extractErrorDetails,
  isResourceExhaustedError,
  clipTextForLog,
};
