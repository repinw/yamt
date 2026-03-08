const test = require("node:test");
const assert = require("node:assert/strict");

const {
  acquireRateLimitSlot,
} = require("../../src/shared/rate_limit");

function createRateLimitDb({ nextAllowedAt }) {
  const state = {
    data: {
      next_allowed_at: nextAllowedAt,
    },
  };

  return {
    state,
    collection() {
      return {
        doc() {
          return { id: "gate-doc" };
        },
      };
    },
    async runTransaction(work) {
      const transaction = {
        async get() {
          return {
            exists: true,
            data() {
              return { ...state.data };
            },
          };
        },
        set(_ref, value, options) {
          const merge = options?.merge === true;
          if (!merge) {
            state.data = { ...value };
            return;
          }
          state.data = { ...state.data, ...value };
        },
      };
      return work(transaction);
    },
  };
}

test("acquireRateLimitSlot respects next_allowed_at when nowMs is earlier", async () => {
  const dbClient = createRateLimitDb({
    nextAllowedAt: new Date("2026-03-08T12:00:10.000Z"),
  });
  const nowMs = Date.parse("2026-03-08T12:00:00.000Z");

  const slot = await acquireRateLimitSlot({
    dbClient,
    collection: "ai_rate_limits",
    documentId: "barcode_enrichment",
    minIntervalMs: 25 * 1000,
    nowMs,
  });

  assert.equal(slot.allowed, true);
  assert.equal(
    slot.reservedAtMs,
    Date.parse("2026-03-08T12:00:10.000Z"),
  );
  assert.equal(slot.waitMs, 10 * 1000);
  assert.equal(
    dbClient.state.data.next_allowed_at.getTime(),
    Date.parse("2026-03-08T12:00:35.000Z"),
  );
});

test("acquireRateLimitSlot rejects reservation when max wait is exceeded", async () => {
  const dbClient = createRateLimitDb({
    nextAllowedAt: new Date("2026-03-08T12:00:30.000Z"),
  });
  const nowMs = Date.parse("2026-03-08T12:00:00.000Z");

  const slot = await acquireRateLimitSlot({
    dbClient,
    collection: "ai_rate_limits",
    documentId: "barcode_enrichment",
    minIntervalMs: 25 * 1000,
    maxWaitMs: 5 * 1000,
    nowMs,
  });

  assert.equal(slot.allowed, false);
  assert.equal(
    slot.reservedAtMs,
    Date.parse("2026-03-08T12:00:30.000Z"),
  );
  assert.equal(slot.waitMs, 30 * 1000);
  assert.equal(
    dbClient.state.data.next_allowed_at.getTime(),
    Date.parse("2026-03-08T12:00:30.000Z"),
  );
});
