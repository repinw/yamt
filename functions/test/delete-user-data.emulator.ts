/**
 * Runs deleteUserData against the Firestore emulator:
 *   npm run test:emulator
 * Storage is a fake FileStore; the emulator never talks to the real project.
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';

import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

import { FileStore, deleteUserData } from '../src/delete-user-data';

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
if (!emulatorHost) {
  throw new Error('FIRESTORE_EMULATOR_HOST is not set; run this through firebase emulators:exec');
}
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-yamt-functions';
initializeApp({ projectId });
const db = getFirestore();

class FakeFileStore implements FileStore {
  readonly paths = new Set<string>();

  constructor(paths: string[] = []) {
    paths.forEach((path) => this.paths.add(path));
  }

  async deletePrefix(prefix: string): Promise<number> {
    const matching = [...this.paths].filter((path) => path.startsWith(prefix));
    matching.forEach((path) => this.paths.delete(path));
    return matching.length;
  }
}

function joined(seconds: number): Timestamp {
  return Timestamp.fromMillis(seconds * 1000);
}

async function set(path: string, data: Record<string, unknown> = {}): Promise<void> {
  await db.doc(path).set(data);
}

async function ids(path: string): Promise<string[]> {
  const snapshot = await db.collection(path).get();
  return snapshot.docs.map((doc) => doc.id).sort();
}

async function subcollections(path: string): Promise<string[]> {
  const collections = await db.doc(path).listCollections();
  return collections.map((collection) => collection.id).sort();
}

async function exists(path: string): Promise<boolean> {
  return (await db.doc(path).get()).exists;
}

describe('deleteUserData (Firestore emulator)', () => {
  beforeEach(async () => {
    const url = `http://${emulatorHost}/emulator/v1/projects/${projectId}/databases/(default)/documents`;
    const response = await fetch(url, { method: 'DELETE' });
    assert.equal(response.ok, true, `clearing the emulator failed: ${response.status}`);
  });

  it('deletes a sole household, leaves a shared one with a new admin and keeps the rest', async () => {
    await set('users/u', { householdId: 'shared', ownHouseholdId: 'own' });
    await set('users/u/calorie_entries/e1', { cipher: 'x' });
    await set('users/u/private/data_key', { wrapped: 'x' });
    await set('users/v', { householdId: 'shared', ownHouseholdId: 'v-own' });

    await set('households/own', { created_at: joined(1) });
    await set('households/own/members/u', { uid: 'u', role: 'admin', joined_at: joined(1) });
    await set('households/own/keys/u', { wrapped: 'k' });
    await set('households/own/inventory_items/i1', { name: 'x' });
    await set('households/own/inventory_items/i1/nested/n1', { name: 'x' });
    await set('households/own/prepared_meals/p1', { name: 'x' });

    await set('households/shared', { created_at: joined(1) });
    await set('households/shared/members/u', { uid: 'u', role: 'admin', joined_at: joined(1) });
    await set('households/shared/members/v', { uid: 'v', role: 'member', joined_at: joined(5) });
    await set('households/shared/members/w', { uid: 'w', role: 'member', joined_at: joined(3) });
    await set('households/shared/keys/u', { wrapped: 'k' });
    await set('households/shared/keys/v', { wrapped: 'k' });
    await set('households/shared/key_restores/u', { wrapped: 'k' });
    await set('households/shared/inventory_items/s1', { name: 'x' });

    await set('households/other', { created_at: joined(1) });
    await set('households/other/members/x', { uid: 'x', role: 'admin', joined_at: joined(1) });
    await set('households/other/inventory_items/o1', { name: 'x' });

    await set('household_invites/own-code', { householdId: 'own' });
    await set('household_invites/shared-code', { householdId: 'shared' });
    await set('global_food_items/g1', { name: 'x' });
    // A `members` collection outside households/ must not count as a membership.
    await set('clubs/c1/members/u', { uid: 'u', role: 'admin' });

    const files = new FakeFileStore([
      'users/u/legacy.jpg',
      'households/own/kitchen_utensils/1.jpg',
      'households/own/recipes/2.jpg',
      'households/shared/recipes/3.jpg',
      'users/v/legacy.jpg',
    ]);

    const summary = await deleteUserData(db, files, 'u');

    assert.equal(summary.householdsDeleted, 1);
    assert.equal(summary.householdsLeft, 1);
    assert.equal(summary.adminsPromoted, 1);
    assert.equal(summary.invitesDeleted, 1);
    assert.equal(summary.storageFilesDeleted, 3);

    assert.equal(await exists('households/own'), false);
    assert.deepEqual(await subcollections('households/own'), []);
    assert.deepEqual(await ids('household_invites'), ['shared-code']);

    assert.deepEqual(await ids('households/shared/members'), ['v', 'w']);
    assert.equal((await db.doc('households/shared/members/w').get()).get('role'), 'admin');
    assert.equal((await db.doc('households/shared/members/v').get()).get('role'), 'member');
    assert.deepEqual(await ids('households/shared/keys'), ['v']);
    assert.deepEqual(await ids('households/shared/key_restores'), []);
    assert.deepEqual(await ids('households/shared/inventory_items'), ['s1']);

    assert.deepEqual(await ids('households/other/members'), ['x']);
    assert.deepEqual(await ids('households/other/inventory_items'), ['o1']);

    assert.equal(await exists('users/u'), false);
    assert.deepEqual(await subcollections('users/u'), []);
    assert.equal(await exists('users/v'), true);
    assert.equal(await exists('global_food_items/g1'), true);
    assert.equal(await exists('clubs/c1/members/u'), true);
    assert.deepEqual([...files.paths].sort(), [
      'households/shared/recipes/3.jpg',
      'users/v/legacy.jpg',
    ]);

    const again = await deleteUserData(db, files, 'u');
    assert.equal(again.householdsDeleted, 0);
    assert.equal(again.householdsLeft, 0);
    assert.equal(again.adminsPromoted, 0);
    assert.equal(again.invitesDeleted, 0);
    assert.equal(again.storageFilesDeleted, 0);
    assert.deepEqual(await ids('households/shared/members'), ['v', 'w']);
  });

  it('finishes a sole household that an earlier run left half deleted', async () => {
    // Household doc and keys already gone, member document and some data left.
    await set('households/h/members/u', { uid: 'u', role: 'admin', joined_at: joined(1) });
    await set('households/h/inventory_items/i2', { name: 'x' });
    await set('household_invites/h-code', { householdId: 'h' });

    const summary = await deleteUserData(db, new FakeFileStore(), 'u');

    assert.equal(summary.householdsDeleted, 1);
    assert.deepEqual(await subcollections('households/h'), []);
    assert.deepEqual(await ids('household_invites'), []);
  });

  it('deletes an own household without members found through the profile only', async () => {
    await set('users/u', { householdId: 'joined', ownHouseholdId: 'own' });
    await set('households/own', { created_at: joined(1) });
    await set('households/own/inventory_items/i1', { name: 'x' });
    await set('households/joined', { created_at: joined(1) });
    await set('households/joined/members/a', { uid: 'a', role: 'admin', joined_at: joined(1) });
    await set('households/joined/inventory_items/j1', { name: 'x' });

    const summary = await deleteUserData(db, new FakeFileStore(), 'u');

    assert.equal(summary.householdsDeleted, 1);
    assert.equal(summary.householdsLeft, 0);
    assert.equal(await exists('households/own'), false);
    assert.deepEqual(await subcollections('households/own'), []);
    assert.deepEqual(await ids('households/joined/members'), ['a']);
    assert.deepEqual(await ids('households/joined/inventory_items'), ['j1']);
  });

  it('keeps an admin when two accounts of one household are deleted at the same time', async () => {
    await set('households/h', { created_at: joined(1) });
    await set('households/h/members/a', { uid: 'a', role: 'admin', joined_at: joined(1) });
    await set('households/h/members/b', { uid: 'b', role: 'member', joined_at: joined(2) });
    await set('households/h/members/c', { uid: 'c', role: 'member', joined_at: joined(3) });
    await set('households/h/inventory_items/i1', { name: 'x' });

    const files = new FakeFileStore();
    await Promise.all([deleteUserData(db, files, 'a'), deleteUserData(db, files, 'b')]);

    assert.deepEqual(await ids('households/h/members'), ['c']);
    assert.equal((await db.doc('households/h/members/c').get()).get('role'), 'admin');
    assert.deepEqual(await ids('households/h/inventory_items'), ['i1']);
  });

  it('deletes the household when its last two members are deleted at the same time', async () => {
    await set('households/h', { created_at: joined(1) });
    await set('households/h/members/a', { uid: 'a', role: 'admin', joined_at: joined(1) });
    await set('households/h/members/b', { uid: 'b', role: 'member', joined_at: joined(2) });
    await set('households/h/inventory_items/i1', { name: 'x' });

    const files = new FakeFileStore(['households/h/recipes/1.jpg']);
    await Promise.all([deleteUserData(db, files, 'a'), deleteUserData(db, files, 'b')]);

    assert.equal(await exists('households/h'), false);
    assert.deepEqual(await subcollections('households/h'), []);
    assert.deepEqual([...files.paths], []);
  });
});
