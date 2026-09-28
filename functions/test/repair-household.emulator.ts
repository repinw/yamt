/**
 * Runs repairHousehold against the Firestore emulator:
 *   npm run test:emulator
 * Storage is a fake FileStore; the emulator never talks to the real project.
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';

import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

import { FileStore } from '../src/delete-user-data';
import { repairHousehold } from '../src/repair-household';

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
if (!emulatorHost) {
  throw new Error('FIRESTORE_EMULATOR_HOST is not set; run this through firebase emulators:exec');
}
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-yamt-functions';
if (getApps().length === 0) {
  initializeApp({ projectId });
}
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

async function exists(path: string): Promise<boolean> {
  return (await db.doc(path).get()).exists;
}

describe('repairHousehold (Firestore emulator)', () => {
  beforeEach(async () => {
    const url = `http://${emulatorHost}/emulator/v1/projects/${projectId}/databases/(default)/documents`;
    const response = await fetch(url, { method: 'DELETE' });
    assert.equal(response.ok, true, `clearing the emulator failed: ${response.status}`);
  });

  it('deletes a household that its last member left', async () => {
    await set('households/h', { created_at: joined(1) });
    await set('households/h/keys/gone', { wrapped_key: 'k' });
    await set('households/h/inventory_items/i1', { name: 'x' });
    await set('households/other', { created_at: joined(1) });
    await set('households/other/members/x', { uid: 'x', role: 'admin', joined_at: joined(1) });
    await set('household_invites/h-code', { householdId: 'h' });
    await set('household_invites/other-code', { householdId: 'other' });
    const files = new FakeFileStore(['households/h/recipes/1.jpg', 'households/other/recipes/2.jpg']);

    assert.equal(await repairHousehold(db, files, 'h'), 'delete-household');

    assert.equal(await exists('households/h'), false);
    assert.deepEqual(await db.doc('households/h').listCollections(), []);
    assert.deepEqual(await ids('household_invites'), ['other-code']);
    assert.deepEqual([...files.paths], ['households/other/recipes/2.jpg']);
    assert.equal(await exists('households/other'), true);
  });

  it('makes the member who joined first admin when no admin is left', async () => {
    await set('households/h', { created_at: joined(1) });
    await set('households/h/members/late', { uid: 'late', role: 'member', joined_at: joined(9) });
    await set('households/h/members/early', { uid: 'early', role: 'member', joined_at: joined(2) });
    await set('households/h/inventory_items/i1', { name: 'x' });

    assert.equal(await repairHousehold(db, new FakeFileStore(), 'h'), 'promote');

    assert.equal((await db.doc('households/h/members/early').get()).get('role'), 'admin');
    assert.equal((await db.doc('households/h/members/late').get()).get('role'), 'member');
    assert.deepEqual(await ids('households/h/inventory_items'), ['i1']);
  });

  it('leaves a household with an admin alone', async () => {
    await set('households/h', { created_at: joined(1) });
    await set('households/h/members/a', { uid: 'a', role: 'admin', joined_at: joined(1) });
    await set('households/h/inventory_items/i1', { name: 'x' });

    assert.equal(await repairHousehold(db, new FakeFileStore(), 'h'), 'none');

    assert.equal(await exists('households/h'), true);
    assert.deepEqual(await ids('households/h/inventory_items'), ['i1']);
  });
});
