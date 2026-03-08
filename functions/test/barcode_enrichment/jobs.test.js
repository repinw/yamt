const test = require("node:test");
const assert = require("node:assert/strict");

const {
  createJobService,
} = require("../../src/barcode_enrichment/jobs");

function createMemoryJobRef(initialData) {
  const state = {
    exists: initialData != null,
    data: initialData == null ? null : { ...initialData },
  };

  function applySet(value, options) {
    const merge = options?.merge === true;
    if (!merge || state.data == null) {
      state.data = { ...value };
    } else {
      state.data = { ...state.data, ...value };
    }
    state.exists = true;
  }

  const ref = {
    async get() {
      return {
        exists: state.exists,
        data() {
          return state.data == null ? undefined : { ...state.data };
        },
      };
    },
    async set(value, options) {
      applySet(value, options);
    },
  };

  return { ref, state, applySet };
}

function createTransactionalDb(memory) {
  let queue = Promise.resolve();
  return {
    runTransaction(work) {
      const run = async () => {
        const tx = {
          async get() {
            return memory.ref.get();
          },
          set(_ignoredRef, value, options) {
            memory.applySet(value, options);
          },
        };
        return work(tx);
      };
      const execution = queue.then(run, run);
      queue = execution.catch(() => {});
      return execution;
    },
  };
}

test("lockQueuedJob serializes concurrent lock attempts", async () => {
  const memory = createMemoryJobRef({
    status: "queued",
    attempts: 0,
  });
  const service = createJobService({
    dbClient: createTransactionalDb(memory),
    maxJobAttempts: 3,
    nowIsoValue: () => "2026-03-04T10:00:00.000Z",
  });

  const [first, second] = await Promise.all([
    service.lockQueuedJob(memory.ref),
    service.lockQueuedJob(memory.ref),
  ]);

  assert.equal(first.shouldProcess, true);
  assert.equal(first.attempts, 1);
  assert.equal(second.shouldProcess, false);
  assert.equal(second.attempts, 1);
  assert.equal(memory.state.data.status, "running");
  assert.equal(memory.state.data.attempts, 1);
});

test("lockQueuedJob stops when max attempts is exceeded", async () => {
  const memory = createMemoryJobRef({
    status: "queued",
    attempts: 3,
  });
  const service = createJobService({
    dbClient: createTransactionalDb(memory),
    maxJobAttempts: 3,
    nowIsoValue: () => "2026-03-04T10:00:00.000Z",
  });

  const result = await service.lockQueuedJob(memory.ref);

  assert.equal(result.shouldProcess, false);
  assert.equal(result.attempts, 4);
  assert.equal(memory.state.data.status, "failed");
  assert.equal(memory.state.data.lastError, "max_attempts_exceeded");
});

test("lockQueuedJob skips jobs that are not in queued state", async () => {
  const memory = createMemoryJobRef({
    status: "backoff_wait",
    attempts: 1,
  });
  const service = createJobService({
    dbClient: createTransactionalDb(memory),
  });

  const result = await service.lockQueuedJob(memory.ref);

  assert.equal(result.shouldProcess, false);
  assert.equal(result.attempts, 1);
  assert.equal(memory.state.data.status, "backoff_wait");
  assert.equal(memory.state.data.attempts, 1);
});

test("markJobResourceExhausted marks job as backoff_wait", async () => {
  const memory = createMemoryJobRef({
    status: "running",
    attempts: 1,
    resourceExhaustedCount: 0,
  });
  const service = createJobService({
    dbClient: createTransactionalDb(memory),
    nowIsoValue: () => "2026-03-04T10:00:00.000Z",
    nowMsValue: () => Date.parse("2026-03-04T10:00:00.000Z"),
    randomValue: () => 0,
    resourceExhaustedBaseDelayMs: 60 * 1000,
    resourceExhaustedMaxDelayMs: 30 * 60 * 1000,
    maxResourceExhaustedRetries: 8,
  });

  await service.markJobResourceExhausted({
    jobRef: memory.ref,
    attempts: 1,
    error: "resource_exhausted_429",
  });

  assert.equal(memory.state.data.status, "backoff_wait");
  assert.equal(memory.state.data.attempts, 0);
  assert.equal(memory.state.data.errorCode, "resource_exhausted");
  assert.equal(memory.state.data.resourceExhaustedCount, 1);
  assert.equal(typeof memory.state.data.nextAttemptAt, "string");
  assert.equal(
    memory.state.data.nextAttemptAt,
    "2026-03-04T10:01:00.000Z",
  );
});

test("markJobResourceExhausted fails after max resource retries", async () => {
  const memory = createMemoryJobRef({
    status: "running",
    attempts: 2,
    resourceExhaustedCount: 2,
  });
  const service = createJobService({
    dbClient: createTransactionalDb(memory),
    nowIsoValue: () => "2026-03-04T10:00:00.000Z",
    nowMsValue: () => Date.parse("2026-03-04T10:00:00.000Z"),
    maxResourceExhaustedRetries: 2,
  });

  await service.markJobResourceExhausted({
    jobRef: memory.ref,
    attempts: 2,
    error: "resource_exhausted_429",
  });

  assert.equal(memory.state.data.status, "failed");
  assert.equal(memory.state.data.errorCode, "resource_exhausted");
  assert.equal(memory.state.data.resourceExhaustedCount, 3);
  assert.equal(memory.state.data.attempts, 1);
  assert.equal(memory.state.data.nextAttemptAt, null);
});
