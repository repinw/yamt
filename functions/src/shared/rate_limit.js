function readTimestampMs(value) {
  if (!value) {
    return null;
  }

  if (typeof value.toMillis === "function") {
    const millis = value.toMillis();
    if (Number.isFinite(Number(millis))) {
      return Number(millis);
    }
  }

  if (typeof value.toDate === "function") {
    const date = value.toDate();
    if (date instanceof Date) {
      return date.getTime();
    }
  }

  if (value instanceof Date) {
    return value.getTime();
  }

  const numeric = Number(value);
  if (Number.isFinite(numeric)) {
    return numeric;
  }

  if (typeof value === "string") {
    const parsed = Date.parse(value.trim());
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return null;
}

async function acquireRateLimitSlot({
  dbClient,
  collection,
  documentId,
  minIntervalMs,
  nowMs,
  maxWaitMs,
  serializeTimestampValue = (valueMs) => new Date(valueMs),
  serverTimestampValue,
}) {
  const gateRef = dbClient.collection(collection).doc(documentId);
  return dbClient.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(gateRef);
    const data = snapshot.exists ? snapshot.data() ?? {} : {};
    const nextAllowedAtMs = readTimestampMs(data.next_allowed_at) ?? 0;
    const reservedAtMs = Math.max(nowMs, nextAllowedAtMs);
    const waitMs = Math.max(0, reservedAtMs - nowMs);

    if (shouldRejectRateLimitReservation({ waitMs, maxWaitMs })) {
      return {
        allowed: false,
        reservedAtMs,
        waitMs,
      };
    }

    const nextAtMs = reservedAtMs + minIntervalMs;
    const payload = {
      next_allowed_at: serializeTimestampValue(nextAtMs),
    };
    if (serverTimestampValue !== undefined) {
      payload.updated_at = serverTimestampValue;
    }

    transaction.set(gateRef, payload, { merge: true });

    return {
      allowed: true,
      reservedAtMs,
      waitMs,
    };
  });
}

async function applyRateLimitCooldown({
  dbClient,
  collection,
  documentId,
  cooldownMs,
  nowMs,
  serializeTimestampValue = (valueMs) => new Date(valueMs),
  serverTimestampValue,
}) {
  const gateRef = dbClient.collection(collection).doc(documentId);
  await dbClient.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(gateRef);
    const data = snapshot.exists ? snapshot.data() ?? {} : {};
    const currentNextAllowedAtMs = readTimestampMs(data.next_allowed_at) ?? 0;
    const cooldownUntilMs = nowMs + cooldownMs;
    const nextAllowedAtMs = Math.max(currentNextAllowedAtMs, cooldownUntilMs);

    const payload = {
      next_allowed_at: serializeTimestampValue(nextAllowedAtMs),
    };
    if (serverTimestampValue !== undefined) {
      payload.updated_at = serverTimestampValue;
    }

    transaction.set(gateRef, payload, { merge: true });
  });
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

function shouldRejectRateLimitReservation({ waitMs, maxWaitMs }) {
  if (!Number.isFinite(Number(maxWaitMs))) {
    return false;
  }
  const normalizedMaxWaitMs = Math.max(0, Number(maxWaitMs));
  return waitMs > normalizedMaxWaitMs;
}

module.exports = {
  readTimestampMs,
  acquireRateLimitSlot,
  applyRateLimitCooldown,
  waitUntil,
};
