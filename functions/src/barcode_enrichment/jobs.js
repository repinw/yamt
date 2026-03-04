const { db, MAX_JOB_ATTEMPTS } = require("./runtime");
const {
  nowIso,
  readPositiveInt,
  readString,
  normalizeCandidates,
} = require("./helpers");

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

async function markJobResourceExhausted({ jobRef, attempts, error }) {
  const updatedAt = nowIso();
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

module.exports = {
  lockQueuedJob,
  markJobDone,
  markJobNoResult,
  markJobFailed,
  markJobResourceExhausted,
};
