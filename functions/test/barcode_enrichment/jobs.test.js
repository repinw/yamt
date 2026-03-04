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
