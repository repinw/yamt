import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  account,
  encrypted,
  guest,
  inHours,
  rulesEnvironment,
  seedHousehold,
  serverTime,
} from './rules-env';

const code = 'InviteCode0123456789';

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

/** Writes an invite of [householdId] with the code [inviteCode]. */
async function seedInvite(
  householdId: string,
  { inviteCode = code, expiresInHours = 24 } = {},
): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`household_invites/${inviteCode}`).set({
      householdId,
      expiresAt: inHours(expiresInHours),
      wrapped_household_key: 'wrapped',
    });
  });
}

/** Joins [householdId] as [uid] the way the app does: member entry, key, and the used invite, in one batch. */
function join(
  uid: string,
  householdId: string,
  { inviteCode = code, role = 'member', deleteInvite = true } = {},
): Promise<void> {
  const db = account(env, uid).firestore();
  const batch = db.batch();
  batch.set(db.doc(`households/${householdId}/members/${uid}`), {
    uid,
    role,
    joined_at: serverTime(),
    invite_code: inviteCode,
  });
  batch.set(db.doc(`households/${householdId}/keys/${uid}`), { wrapped_key: 'wrapped' });
  if (deleteInvite) {
    batch.delete(db.doc(`household_invites/${inviteCode}`));
  }
  return batch.commit();
}

describe('creating a household', () => {
  it('creates the household together with its admin entry', async () => {
    const db = account(env, 'ada').firestore();
    const batch = db.batch();
    batch.set(db.doc('households/h1'), { created_at: serverTime() });
    batch.set(db.doc('households/h1/members/ada'), {
      uid: 'ada',
      role: 'admin',
      joined_at: serverTime(),
    });
    await assertSucceeds(batch.commit());
  });

  it('refuses a household without its admin entry', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(db.doc('households/h1').set({ created_at: serverTime() }));
  });

  it('refuses an admin entry in a household that already exists', async () => {
    await seedHousehold(env, 'h1', 'ada');
    const db = account(env, 'eve').firestore();
    await assertFails(
      db.doc('households/h1/members/eve').set({
        uid: 'eve',
        role: 'admin',
        joined_at: serverTime(),
      }),
    );
  });
});

describe('invites', () => {
  beforeEach(async () => {
    await seedHousehold(env, 'h1', 'ada', ['bob']);
  });

  const invite = () => ({
    householdId: 'h1',
    expiresAt: inHours(24),
    wrapped_household_key: 'wrapped',
  });

  it('lets the admin invite', async () => {
    const db = account(env, 'ada').firestore();
    await assertSucceeds(db.doc(`household_invites/${code}`).set(invite()));
  });

  it('refuses an invite by a member who is not the admin', async () => {
    const db = account(env, 'bob').firestore();
    await assertFails(db.doc(`household_invites/${code}`).set(invite()));
  });

  it('refuses an invite by an anonymous admin', async () => {
    const db = guest(env, 'ada').firestore();
    await assertFails(db.doc(`household_invites/${code}`).set(invite()));
  });

  it('refuses an invite code that is short enough to guess', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(db.doc('household_invites/abc123').set(invite()));
  });

  it('refuses an invite that lasts longer than a day', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(
      db.doc(`household_invites/${code}`).set({ ...invite(), expiresAt: inHours(48) }),
    );
  });

  it('lets a signed-in user read an invite by its code, but not list them', async () => {
    await seedInvite('h1');
    const db = account(env, 'carl').firestore();
    await assertSucceeds(db.doc(`household_invites/${code}`).get());
    await assertFails(db.collection('household_invites').get());
  });
});

describe('joining with an invite', () => {
  beforeEach(async () => {
    await seedHousehold(env, 'h1', 'ada');
  });

  it('joins with a valid invite and uses it up', async () => {
    await seedInvite('h1');
    await assertSucceeds(join('carl', 'h1'));
  });

  it('refuses a join that keeps the invite', async () => {
    await seedInvite('h1');
    await assertFails(join('carl', 'h1', { deleteInvite: false }));
  });

  it('refuses a join as admin', async () => {
    await seedInvite('h1');
    await assertFails(join('carl', 'h1', { role: 'admin' }));
  });

  it('refuses an expired invite', async () => {
    await seedInvite('h1', { expiresInHours: -1 });
    await assertFails(join('carl', 'h1'));
  });

  it('refuses an invite of another household (forged invite)', async () => {
    // Carl is the admin of h2, so he may delete its invite in the same
    // batch; only the household check of the invite stops him joining h1.
    await seedHousehold(env, 'h2', 'carl');
    await seedInvite('h2');
    await assertFails(join('carl', 'h1'));
  });

  it('refuses a join without any invite', async () => {
    await assertFails(join('carl', 'h1', { deleteInvite: false }));
  });

  it('refuses a member entry written for another user', async () => {
    await seedInvite('h1');
    const db = account(env, 'eve').firestore();
    await assertFails(
      db.doc('households/h1/members/carl').set({
        uid: 'carl',
        role: 'member',
        joined_at: serverTime(),
        invite_code: code,
      }),
    );
  });

  it('lets an invite in only one person', async () => {
    await seedInvite('h1');
    await assertSucceeds(join('carl', 'h1'));
    await env.withSecurityRulesDisabled(async (context) => {
      const invite = await context.firestore().doc(`household_invites/${code}`).get();
      if (invite.exists) {
        throw new Error('the join kept the invite');
      }
    });
    // The used invite is gone, so it lets nobody else in, nor Carl again.
    await assertFails(join('dan', 'h1', { deleteInvite: false }));
  });
});

describe('admin handover', () => {
  beforeEach(async () => {
    await seedHousehold(env, 'h1', 'ada', ['bob', 'carl']);
  });

  it('makes a member admin while the admin turns member', async () => {
    const db = account(env, 'ada').firestore();
    const batch = db.batch();
    batch.update(db.doc('households/h1/members/bob'), { role: 'admin' });
    batch.update(db.doc('households/h1/members/ada'), { role: 'member' });
    await assertSucceeds(batch.commit());
  });

  it('makes a member admin while the admin leaves', async () => {
    const db = account(env, 'ada').firestore();
    const batch = db.batch();
    batch.update(db.doc('households/h1/members/bob'), { role: 'admin' });
    batch.delete(db.doc('households/h1/members/ada'));
    await assertSucceeds(batch.commit());
  });

  it('refuses a second admin', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(db.doc('households/h1/members/bob').update({ role: 'admin' }));
  });

  it('refuses a member who makes themself admin', async () => {
    const db = account(env, 'bob').firestore();
    await assertFails(db.doc('households/h1/members/bob').update({ role: 'admin' }));
  });

  it('refuses a role that does not exist', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(db.doc('households/h1/members/bob').update({ role: 'owner' }));
  });

  it('refuses a change of anything but the role', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(db.doc('households/h1/members/bob').update({ uid: 'eve' }));
  });
});

describe('removing a member', () => {
  beforeEach(async () => {
    await seedHousehold(env, 'h1', 'ada', ['bob', 'carl']);
  });

  it('lets the admin remove a member and their key', async () => {
    const db = account(env, 'ada').firestore();
    await assertSucceeds(db.doc('households/h1/members/bob').delete());
    await assertSucceeds(db.doc('households/h1/keys/bob').delete());
  });

  it('lets a member leave', async () => {
    const db = account(env, 'bob').firestore();
    await assertSucceeds(db.doc('households/h1/members/bob').delete());
  });

  it('refuses a member who removes another member', async () => {
    const db = account(env, 'bob').firestore();
    await assertFails(db.doc('households/h1/members/carl').delete());
  });

  it('shuts a removed member out of the household data', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('households/h1/inventory_items/i1').set(encrypted);
      await context.firestore().doc('households/h1/members/bob').delete();
    });
    const db = account(env, 'bob').firestore();
    await assertFails(db.doc('households/h1/inventory_items/i1').get());
    await assertFails(db.doc('households/h1/inventory_items/i2').set(encrypted));
  });

  it('refuses a household delete by the client', async () => {
    const db = account(env, 'ada').firestore();
    await assertFails(db.doc('households/h1').delete());
  });
});

describe('household data', () => {
  beforeEach(async () => {
    await seedHousehold(env, 'h1', 'ada', ['bob']);
    await seedHousehold(env, 'h2', 'dora');
  });

  it('lets a member write encrypted items and read them', async () => {
    const db = account(env, 'bob').firestore();
    await assertSucceeds(db.doc('households/h1/prepared_meals/m1').set(encrypted));
    await assertSucceeds(db.doc('households/h1/prepared_meals/m1').get());
  });

  it('refuses plaintext fields beyond the payload', async () => {
    const db = account(env, 'bob').firestore();
    await assertFails(
      db.doc('households/h1/prepared_meals/m1').set({ ...encrypted, name: 'Linsensuppe' }),
    );
  });

  it('keeps another household out', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('households/h1/inventory_items/i1').set(encrypted);
    });
    const db = account(env, 'dora').firestore();
    await assertFails(db.doc('households/h1/inventory_items/i1').get());
    await assertFails(db.collection('households/h1/inventory_items').get());
    await assertFails(db.doc('households/h1/members/ada').get());
  });

  it('keeps the activity history append-only', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc('households/h1/inventory_activity_events/e1')
        .set({ ...encrypted, happened_at: '2026-10-01T12:00:00.000' });
    });
    const bob = account(env, 'bob').firestore();
    await assertFails(
      bob.doc('households/h1/inventory_activity_events/e1').set({
        ...encrypted,
        happened_at: '2026-10-02T12:00:00.000',
      }),
    );
    await assertFails(bob.doc('households/h1/inventory_activity_events/e1').delete());
    const ada = account(env, 'ada').firestore();
    await assertSucceeds(ada.doc('households/h1/inventory_activity_events/e1').delete());
  });

  it('lets only the owner read their household key', async () => {
    const db = account(env, 'bob').firestore();
    await assertSucceeds(db.doc('households/h1/keys/bob').get());
    await assertFails(db.doc('households/h1/keys/ada').get());
  });
});

describe('profiles of co-members', () => {
  beforeEach(async () => {
    await seedHousehold(env, 'h1', 'ada', ['bob']);
    await seedHousehold(env, 'h2', 'dora');
  });

  it('lets a co-member read the profile', async () => {
    const db = account(env, 'bob').firestore();
    await assertSucceeds(db.doc('users/ada').get());
  });

  it('keeps a user of another household out', async () => {
    const db = account(env, 'dora').firestore();
    await assertFails(db.doc('users/ada').get());
  });

  it('counts only the household the reader is active in', async () => {
    // Bob is still a member of h1 but now active in h2.
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('households/h2/members/bob').set({
        uid: 'bob',
        role: 'member',
        joined_at: new Date(),
      });
      await db.doc('users/bob').set({ uid: 'bob', householdId: 'h2' });
    });
    const db = account(env, 'bob').firestore();
    await assertFails(db.doc('users/ada').get());
    await assertSucceeds(db.doc('users/dora').get());
  });

  it('refuses a co-member who writes the profile', async () => {
    const db = account(env, 'bob').firestore();
    await assertFails(db.doc('users/ada').set({ uid: 'ada', householdId: 'h2' }));
  });
});
