/**
 * The write shapes of the app in the stores (3.7.0). The rules follow
 * expand/contract and never depend on the app version, so every shape an
 * installed app writes must stay allowed. A rule change that fails here
 * breaks the app in the stores: expand the rule instead, and contract it
 * only once the minimum version no longer writes the old shape.
 *
 * Each case copies the document the 3.7.0 code writes (file in the comment).
 * Only paths whose shape the rules check are here.
 */
import { after, before, beforeEach, describe, it } from 'node:test';

import { assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';

import { account, inHours, rulesEnvironment, seedHousehold, serverTime } from './rules-env';

const code = 'InviteCode0123456789';
const payload = 'ciphertext';

let env: RulesTestEnvironment;

before(async () => {
  env = await rulesEnvironment();
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

describe('app 3.7.0 household writes', () => {
  // household/data/household_repository.dart _writeHousehold
  it('creates a household for a new profile', async () => {
    const db = account(env, 'ada').firestore();
    const batch = db.batch();
    batch.set(db.doc('households/h1'), { created_at: serverTime() });
    batch.set(db.doc('households/h1/members/ada'), {
      uid: 'ada',
      role: 'admin',
      joined_at: serverTime(),
    });
    batch.set(db.doc('households/h1/keys/ada'), { wrapped_key: payload });
    batch.set(db.doc('users/ada'), { uid: 'ada', householdId: 'h1', ownHouseholdId: 'h1' });
    await assertSucceeds(batch.commit());
  });

  it('creates a household for an existing profile', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/ada').set({ uid: 'ada' });
    });
    const db = account(env, 'ada').firestore();
    const batch = db.batch();
    batch.set(db.doc('households/h1'), { created_at: serverTime() });
    batch.set(db.doc('households/h1/members/ada'), {
      uid: 'ada',
      role: 'admin',
      joined_at: serverTime(),
    });
    batch.set(db.doc('households/h1/keys/ada'), { wrapped_key: payload });
    batch.update(db.doc('users/ada'), { householdId: 'h1', ownHouseholdId: 'h1' });
    await assertSucceeds(batch.commit());
  });

  // household/data/household_invite_repository.dart: invite and join
  it('invites for one day', async () => {
    await seedHousehold(env, 'h1', 'ada');
    const db = account(env, 'ada').firestore();
    await assertSucceeds(
      db.doc(`household_invites/${code}`).set({
        householdId: 'h1',
        expiresAt: inHours(24),
        wrapped_household_key: payload,
      }),
    );
  });

  it('joins with the invite and names the household on the profile', async () => {
    await seedHousehold(env, 'h1', 'ada');
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`household_invites/${code}`).set({
        householdId: 'h1',
        expiresAt: inHours(24),
        wrapped_household_key: payload,
      });
      await db.doc('users/carl').set({ uid: 'carl', householdId: 'carl-own' });
    });
    const db = account(env, 'carl').firestore();
    const batch = db.batch();
    batch.set(db.doc('households/h1/members/carl'), {
      uid: 'carl',
      role: 'member',
      joined_at: serverTime(),
      invite_code: code,
    });
    batch.set(db.doc('households/h1/keys/carl'), { wrapped_key: payload });
    batch.delete(db.doc(`household_invites/${code}`));
    batch.update(db.doc('users/carl'), { householdId: 'h1' });
    await assertSucceeds(batch.commit());
  });

  // household/data/household_repository.dart _writeDeparture
  it('leaves the household', async () => {
    await seedHousehold(env, 'h1', 'ada', ['bob']);
    const db = account(env, 'bob').firestore();
    const batch = db.batch();
    batch.delete(db.doc('households/h1/keys/bob'));
    batch.delete(db.doc('households/h1/key_restores/bob'));
    batch.delete(db.doc('households/h1/members/bob'));
    await assertSucceeds(batch.commit());
  });

  // household/data/household_key_repository.dart: key restore
  it('asks for the household key and gets it from another member', async () => {
    await seedHousehold(env, 'h1', 'ada', ['bob']);
    await assertSucceeds(
      account(env, 'bob').firestore().doc('households/h1/key_restores/bob').set({}),
    );
    await assertSucceeds(
      account(env, 'ada')
        .firestore()
        .doc('households/h1/key_restores/bob')
        .update({ wrapped_household_key: payload }),
    );
  });
});

describe('app 3.7.0 profile and device writes', () => {
  // auth/domain/user_profile.dart toJson
  it('writes the whole profile', async () => {
    const db = account(env, 'ada').firestore();
    await assertSucceeds(
      db.doc('users/ada').set({
        uid: 'ada',
        householdId: 'h1',
        ownHouseholdId: 'h1',
        email: 'ada@example.com',
        displayName: 'Ada',
        isAnonymous: false,
      }),
    );
    await assertSucceeds(db.doc('users/ada').update({ burn_week_run_state: payload }));
  });

  // app_update/data/app_client_repository.dart
  it('reports the app version of the device', async () => {
    const db = account(env, 'ada').firestore();
    await assertSucceeds(
      db.doc('users/ada/clients/install-1').set({
        app_version: '3.7.0',
        platform: 'android',
        last_seen_at: firebase.firestore.Timestamp.now(),
      }),
    );
  });
});

describe('app 3.7.0 encrypted documents', () => {
  beforeEach(async () => {
    await seedHousehold(env, 'h1', 'ada');
  });

  // household/data/household_key_repository.dart plaintext fields
  const household: [string, Record<string, unknown>][] = [
    [
      'inventory_items',
      { entry_date: '2026-10-01T12:00:00.000', origin: 'manual', is_deposit: false, is_discount: false },
    ],
    ['inventory_discard_events', { discarded_at: '2026-10-01T12:00:00.000' }],
    ['inventory_activity_events', { happened_at: '2026-10-01T12:00:00.000' }],
    ['shopping_list_items', {}],
    ['prepared_meals', {}],
    ['prepared_meal_templates', {}],
    ['kitchen_utensils', {}],
  ];
  for (const [collection, plaintext] of household) {
    it(`writes a household ${collection} document`, async () => {
      const db = account(env, 'ada').firestore();
      await assertSucceeds(db.doc(`households/h1/${collection}/d1`).set({ ...plaintext, payload }));
    });
  }

  // calories/data/calorie_entry_document_codec.dart: logged_at is a Timestamp
  for (const collection of ['calorie_entries', 'planned_entries']) {
    it(`writes a ${collection} document`, async () => {
      const db = account(env, 'ada').firestore();
      await assertSucceeds(
        db.doc(`users/ada/${collection}/d1`).set({ logged_at: new Date(), payload }),
      );
    });
  }

  for (const collection of [
    'calorie_settings',
    'health_weights',
    'health_weight_samples',
    'calorie_product_overrides',
  ]) {
    it(`writes a ${collection} document`, async () => {
      const db = account(env, 'ada').firestore();
      await assertSucceeds(db.doc(`users/ada/${collection}/d1`).set({ payload }));
    });
  }

  it('backs up the data key', async () => {
    const db = account(env, 'ada').firestore();
    await assertSucceeds(db.doc('users/ada/private/data_key').set({ wrapped_key: payload }));
  });
});
