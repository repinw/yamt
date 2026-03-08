const logger = require("firebase-functions/logger");
const {
  getAi,
  MODEL_NAME,
  MODEL_LOCATION,
  MAX_OUTPUT_TOKENS,
  MODEL_THINKING_LEVEL,
} = require("./runtime");
const {
  parseResponseAsJson,
  normalizeCandidates,
  readBoolean,
  clipTextForLog,
  extractTextResponse,
} = require("./helpers");

async function resolveCandidates({ itemName, brand, storeName, weight }) {
  const prompt = buildSinglePrompt({ itemName, brand, storeName, weight });
  logger.info("Barcode AI request payload.", {
    model: MODEL_NAME,
    location: MODEL_LOCATION,
    prompt: clipTextForLog(prompt),
  });

  const ai = getAi();
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
  const uncertain = readBoolean(parsed?.is_uncertain);
  const selectedBarcode = candidates.length > 0 ? candidates[0] : null;

  logger.info("Barcode AI response payload.", {
    model: MODEL_NAME,
    location: MODEL_LOCATION,
    responseText: clipTextForLog(extractTextResponse(response)),
    rawCandidates,
    candidates,
    uncertain,
    selectedBarcode,
    found: selectedBarcode !== null,
  });

  return {
    candidates,
    uncertain,
  };
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
    '  "ean_candidates": ["digits_only"],',
    '  "is_uncertain": true',
    "}",
    "",
    "Regeln:",
    "- Nur Ziffern mit 8 bis 14 Stellen.",
    "- Maximal 5 Kandidaten.",
    "- Wenn sicher: is_uncertain=false.",
    "- Wenn unsicher: gib den wahrscheinlichsten Kandidaten trotzdem als",
    "  ersten Treffer und setze is_uncertain=true.",
    "- Wenn kein vernuenftiger Kandidat moeglich: leeres Array und",
    "  is_uncertain=true.",
    "",
    `item_name: ${safeItemName}`,
    `store_name: ${safeStoreName}`,
    `brand: ${safeBrand}`,
    `weight: ${safeWeight}`,
  ].join("\n");
}

module.exports = {
  resolveCandidates,
  buildSinglePrompt,
};
