const { db, MAX_JOB_ATTEMPTS } = require("./runtime");
const {
  nowIso,
  readPositiveInt,
  readString,
  normalizeCandidates,
} = require("./helpers");

function createJobService({
  dbClient = db,
  maxJobAttempts = MAX_JOB_ATTEMPTS,
  nowIsoValue = nowIso,
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
      },
      { merge: true },
    );
  }

  async function markJobResourceExhausted({ jobRef, attempts, error }) {
    const updatedAt = nowIsoValue();
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

  return {
    lockQueuedJob,
    markJobDone,
    markJobNoResult,
    markJobFailed,
    markJobResourceExhausted,
  };
}

const defaultJobService = createJobService();

module.exports = {
  createJobService,
  ...defaultJobService,
};
