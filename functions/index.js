const { onCall } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { GoogleGenAI } = require("@google/genai");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

const FUNCTION_REGION = "europe-west1";
const MODEL_NAME = "gemini-3.1-pro-preview";
const MODEL_LOCATION = "global";
const MAX_OUTPUT_TOKENS = 2048;

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
      const itemRef = db
        .collection("users")
        .doc(uid)
        .collection("inventory_items")
        .doc(itemId);
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
      const fingerprint = readString(request.data?.fingerprint) ??
        readString(itemData.foodFingerprint) ??
        computeFoodFingerprint({ name: itemName, brand });
      const trigger = readString(request.data?.trigger) ?? "manual_search";

      const requestedAt = new Date().toISOString();
      await itemRef.set(
        {
          foodFingerprint: fingerprint,
          barcodeLookupRequestedAt: requestedAt,
        },
        { merge: true },
      );

      logger.info("Resolving inventory item barcode.", {
        uid,
        itemId,
        fingerprint,
        trigger,
        model: MODEL_NAME,
        location: MODEL_LOCATION,
        sdk: "@google/genai",
      });

      const candidates = await resolveCandidates({
        itemName,
        brand,
        fingerprint,
      });
      const barcode = candidates.length > 0 ? candidates[0] : null;

      if (barcode) {
        await itemRef.set(
          {
            barcode,
            barcodeResolvedAt: new Date().toISOString(),
            barcodeLookupRequestedAt: requestedAt,
            foodFingerprint: fingerprint,
          },
          { merge: true },
        );
        logger.info("Inventory item barcode resolved.", {
          uid,
          itemId,
          fingerprint,
          barcode,
        });
        return {
          success: true,
          found: true,
          barcode,
          candidates,
        };
      }

      logger.info("Inventory item barcode unresolved.", {
        uid,
        itemId,
        fingerprint,
      });
      return {
        success: true,
        found: false,
        barcode: null,
        candidates: [],
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

async function resolveCandidates({ itemName, brand, fingerprint }) {
  const prompt = buildPrompt({ itemName, brand, fingerprint });
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

function buildPrompt({ itemName, brand, fingerprint }) {
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
  for (const rawCandidate of rawCandidates) {
    const normalized = normalizeBarcode(rawCandidate);
    if (!normalized || deduped.includes(normalized)) {
      continue;
    }
    deduped.push(normalized);
    if (deduped.length >= 5) {
      break;
    }
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
  const details = {
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

  return details;
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
