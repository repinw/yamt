const logger = require("firebase-functions/logger");
const { HttpsError } = require("firebase-functions/v2/https");
const { readString } = require("./helpers");

function resolveRequestUid(request, callableName) {
  const authenticatedUid = readString(request?.auth?.uid);
  if (authenticatedUid) {
    return authenticatedUid;
  }

  if (isFunctionsEmulator()) {
    const fallbackUid = readString(request?.data?.userId);
    if (fallbackUid) {
      logger.warn("Using emulator-only uid fallback for callable request.", {
        callableName,
        uid: fallbackUid,
      });
      return fallbackUid;
    }
  }

  throw new HttpsError("unauthenticated", "Authentication is required.");
}

function isFunctionsEmulator() {
  return process.env.FUNCTIONS_EMULATOR === "true";
}

module.exports = {
  resolveRequestUid,
  isFunctionsEmulator,
};
