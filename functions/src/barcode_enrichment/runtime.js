const { GoogleGenAI, ThinkingLevel } = require("@google/genai");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

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

let aiClient = null;

function resolveProjectId() {
  const envProjectId = process.env.GCLOUD_PROJECT ??
    process.env.GOOGLE_CLOUD_PROJECT ??
    process.env.PROJECT_ID;
  if (envProjectId && envProjectId.trim().length > 0) {
    return envProjectId.trim();
  }

  const firebaseConfigRaw = process.env.FIREBASE_CONFIG;
  if (
    typeof firebaseConfigRaw === "string" &&
    firebaseConfigRaw.trim().length > 0
  ) {
    try {
      const parsed = JSON.parse(firebaseConfigRaw);
      const firebaseProjectId = parsed?.projectId;
      if (
        typeof firebaseProjectId === "string" &&
        firebaseProjectId.trim().length > 0
      ) {
        return firebaseProjectId.trim();
      }
    } catch (_) {
      // Ignore parse issues and fallback to missing_project_id.
    }
  }

  return null;
}

function getAi() {
  if (aiClient) {
    return aiClient;
  }

  const projectId = resolveProjectId();
  if (!projectId) {
    throw new Error("missing_project_id_for_vertex_ai");
  }

  aiClient = new GoogleGenAI({
    vertexai: true,
    project: projectId,
    location: MODEL_LOCATION,
  });
  return aiClient;
}

module.exports = {
  db,
  getAi,
  FieldValue,
  USERS_COLLECTION,
  INVENTORY_ITEMS_COLLECTION,
  JOB_COLLECTION,
  GLOBAL_RESOLUTIONS_COLLECTION,
  FUNCTION_REGION,
  MODEL_NAME,
  MODEL_LOCATION,
  MODEL_THINKING_LEVEL,
  MAX_OUTPUT_TOKENS,
  MAX_CANDIDATES_PER_ITEM,
  MAX_ENQUEUE_ITEMS,
  MAX_JOB_RETRIES,
  MAX_JOB_ATTEMPTS,
  WORKER_MAX_INSTANCES,
  MAX_KEYWORD_QUERY_TERMS,
  KEYWORD_QUERY_LIMIT,
  KEYWORD_MATCH_MIN_SCORE,
  KEYWORD_ALIAS_MIN_SCORE,
  LOOKUP_STOPWORDS,
  LOOKUP_GENERIC_TOKENS,
  LOOKUP_TOKEN_ALIASES,
};
