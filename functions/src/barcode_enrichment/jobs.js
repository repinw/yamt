const {
  db,
  MAX_JOB_ATTEMPTS,
  MAX_RESOURCE_EXHAUSTED_RETRIES,
  RESOURCE_EXHAUSTED_BASE_DELAY_MS,
  RESOURCE_EXHAUSTED_MAX_DELAY_MS,
} = require("./runtime");
const {
  nowIso,
  readPositiveInt,
  readString,
  normalizeCandidates,
} = require("./helpers");

function createJobService({
  dbClient = db,
  maxJobAttempts = MAX_JOB_ATTEMPTS,
  maxResourceExhaustedRetries = MAX_RESOURCE_EXHAUSTED_RETRIES,
  resourceExhaustedBaseDelayMs = RESOURCE_EXHAUSTED_BASE_DELAY_MS,
  resourceExhaustedMaxDelayMs = RESOURCE_EXHAUSTED_MAX_DELAY_MS,
  nowIsoValue = nowIso,
  nowMsValue = () => Date.now(),
  randomValue = Math.random,
  normalizeCandidatesValue = normalizeCandidates,
  readPositiveIntValue = readPositiveInt,
  readStringValue = readString,
} = {}) {
  async function lockQueuedJob(jobRef) {
    return dbClient.runTransaction(async (tx) => {
      const snapshot = await tx.get(jobRef);
      if (!snapshot.exists) {
        return { shouldProcess: false, attempts: 0 };
      }

      const data = snapshot.data() ?? {};
      const status = readStringValue(data.status) ?? "queued";
      if (status !== "queued") {
        return {
          shouldProcess: false,
          attempts: readPositiveIntValue(data.attempts),
        };
      }

      const attempts = readPositiveIntValue(data.attempts) + 1;
      const updatedAt = nowIsoValue();
      if (attempts > maxJobAttempts) {
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
          nextAttemptAt: null,
          lastError: null,
          errorCode: null,
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
    barcodeLookupUncertain,
    source,
  }) {
    const updatedAt = nowIsoValue();
    await jobRef.set(
      {
        status: "done",
        attempts,
        updatedAt,
        completedAt: updatedAt,
        fingerprint,
        found,
        barcode: barcode ?? null,
        candidates: normalizeCandidatesValue(candidates),
        barcodeLookupUncertain: Boolean(barcodeLookupUncertain),
        source,
        lastError: null,
        errorCode: null,
        nextAttemptAt: null,
        resourceExhaustedCount: 0,
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
    const updatedAt = nowIsoValue();
    const canRetry = attempts < maxJobAttempts;
    await jobRef.set(
      {
        status: canRetry ? "queued" : "done",
        attempts,
        updatedAt,
        completedAt: canRetry ? null : updatedAt,
        fingerprint,
        found: false,
        barcode: null,
        candidates: normalizeCandidatesValue(candidates),
        source,
        lastError: canRetry ? "no_candidates_retrying" : "no_candidates",
        errorCode: null,
        nextAttemptAt: null,
        resourceExhaustedCount: 0,
      },
      { merge: true },
    );
  }

  async function markJobFailed({ jobRef, attempts, error }) {
    const updatedAt = nowIsoValue();
    const canRetry = attempts < maxJobAttempts;
    await jobRef.set(
      {
        status: canRetry ? "queued" : "failed",
        attempts,
        updatedAt,
        completedAt: canRetry ? null : updatedAt,
        lastError: error,
        nextAttemptAt: null,
      },
      { merge: true },
    );
  }

  async function markJobResourceExhausted({ jobRef, attempts, error }) {
    const snapshot = await jobRef.get();
    const data = snapshot.exists ? snapshot.data() ?? {} : {};
    const currentResourceExhaustedCount = readPositiveIntValue(
      data.resourceExhaustedCount,
    );
    const nextResourceExhaustedCount = currentResourceExhaustedCount + 1;
    const normalizedAttempts = Math.max(0, attempts - 1);
    const updatedAt = nowIsoValue();
    const shouldRetry = nextResourceExhaustedCount <= maxResourceExhaustedRetries;

    if (!shouldRetry) {
      await jobRef.set(
        {
          status: "failed",
          attempts: normalizedAttempts,
          updatedAt,
          completedAt: updatedAt,
          lastError: error,
          errorCode: "resource_exhausted",
          nextAttemptAt: null,
          resourceExhaustedCount: nextResourceExhaustedCount,
        },
        { merge: true },
      );
      return;
    }

    const backoffDelayMs = computeResourceExhaustedBackoffDelayMs({
      attempt: nextResourceExhaustedCount,
      baseDelayMs: resourceExhaustedBaseDelayMs,
      maxDelayMs: resourceExhaustedMaxDelayMs,
      randomValue,
    });
    const nextAttemptAt = new Date(nowMsValue() + backoffDelayMs)
      .toISOString();

    await jobRef.set(
      {
        status: "backoff_wait",
        attempts: normalizedAttempts,
        updatedAt,
        completedAt: null,
        startedAt: null,
        lastError: error,
        errorCode: "resource_exhausted",
        nextAttemptAt,
        resourceExhaustedCount: nextResourceExhaustedCount,
      },
      { merge: true },
    );
  }

  return {
    lockQueuedJob,
    markJobDone,
    markJobNoResult,
    markJobFailed,
    markJobResourceExhausted,
  };
}

const defaultJobService = createJobService();

function computeResourceExhaustedBackoffDelayMs({
  attempt,
  baseDelayMs,
  maxDelayMs,
  randomValue,
}) {
  const safeAttempt = Math.max(1, readPositiveInt(attempt));
  const exponentialDelayMs = baseDelayMs * (2 ** (safeAttempt - 1));
  const cappedDelayMs = Math.min(maxDelayMs, exponentialDelayMs);
  const jitterWindowMs = Math.max(1000, Math.floor(cappedDelayMs * 0.2));
  const jitterMs = Math.floor(
    Math.max(0, randomValue()) * jitterWindowMs,
  );
  return cappedDelayMs + jitterMs;
}

module.exports = {
  createJobService,
  computeResourceExhaustedBackoffDelayMs,
  ...defaultJobService,
};
