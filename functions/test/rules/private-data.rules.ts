import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

import { account, encrypted, rulesEnvironment, seedHousehold } from './rules-env';

let env: RulesTestEnvironment;

before(async () => {
  env = await rulesEnvironment();
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  // Bob shares a household with Ada, yet her health data stays hers.
  await seedHousehold(env, 'h1', 'ada', ['bob']);
});

// Private collections that hold only an encrypted payload.
const payloadOnly = [
  'calorie_settings',
  'health_weights',
  'health_weight_samples',
  'calorie_product_overrides',
];
// Private collections that also keep the time in plaintext for queries.
const timed = ['calorie_entries', 'planned_entries'];

describe('private data of a user', () => {
  for (const collection of payloadOnly) {
    describe(collection, () => {
      const path = `users/ada/${collection}/d1`;

      it('lets the owner write and read an encrypted payload', async () => {
        const db = account(env, 'ada').firestore();
        await assertSucceeds(db.doc(path).set(encrypted));
        await assertSucceeds(db.doc(path).get());
        await assertSucceeds(db.doc(path).delete());
      });

      it('refuses plaintext fields', async () => {
        const db = account(env, 'ada').firestore();
        await assertFails(db.doc(path).set({ ...encrypted, kg: 80.5 }));
      });

      it('refuses a document without a payload string', async () => {
        const db = account(env, 'ada').firestore();
        await assertFails(db.doc(path).set({ payload: 42 }));
        await assertFails(db.doc(path).set({}));
      });

      it('keeps a co-member out', async () => {
        await env.withSecurityRulesDisabled(async (context) => {
          await context.firestore().doc(path).set(encrypted);
        });
        const db = account(env, 'bob').firestore();
        await assertFails(db.doc(path).get());
        await assertFails(db.collection(`users/ada/${collection}`).get());
        await assertFails(db.doc(path).set(encrypted));
        await assertFails(db.doc(path).delete());
      });
    });
  }

  for (const collection of timed) {
    describe(collection, () => {
      const path = `users/ada/${collection}/d1`;

      it('lets the owner write a payload with its time', async () => {
        const db = account(env, 'ada').firestore();
        await assertSucceeds(db.doc(path).set({ ...encrypted, logged_at: new Date() }));
      });

      it('refuses an entry without its time, or with a time as text', async () => {
        const db = account(env, 'ada').firestore();
        await assertFails(db.doc(path).set(encrypted));
        await assertFails(db.doc(path).set({ ...encrypted, logged_at: '2026-10-01' }));
      });

      it('keeps a co-member out', async () => {
        const db = account(env, 'bob').firestore();
        await assertFails(db.doc(path).get());
        await assertFails(db.doc(path).set({ ...encrypted, logged_at: new Date() }));
      });
    });
  }

  it('keeps the data key backup to its owner', async () => {
    const ada = account(env, 'ada').firestore();
    await assertSucceeds(ada.doc('users/ada/private/data_key').set({ wrapped_key: 'w' }));
    const bob = account(env, 'bob').firestore();
    await assertFails(bob.doc('users/ada/private/data_key').get());
  });

  it('closes every path without its own rule', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(db.doc('users/ada/unknown/d1').set(encrypted));
    await assertFails(db.doc('config/feature_flags').get());
    await assertFails(db.doc('anything/d1').set({ uid: 'ada' }));
  });
});
