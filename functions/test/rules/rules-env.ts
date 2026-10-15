/**
 * Shared setup for the security rules tests. They run against the Firestore
 * and Storage emulators with the real firestore.rules and storage.rules:
 *   npm run test:rules
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  initializeTestEnvironment,
  RulesTestContext,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

export const projectId = 'demo-yamt-rules';

// Every refused write would log a warning; the asserts report what matters.
firebase.firestore.setLogLevel('silent');

// The compiled tests sit in functions/build-test/test/rules.
const repoRoot = resolve(__dirname, '../../../..');

export async function rulesEnvironment(): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(repoRoot, 'firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(repoRoot, 'storage.rules'), 'utf8') },
  });
}

/** A user who signed in with an account, not anonymously. */
export function account(env: RulesTestEnvironment, uid: string): RulesTestContext {
  return env.authenticatedContext(uid, { firebase: { sign_in_provider: 'google.com' } });
}

/** A user who signed in anonymously, as a guest. */
export function guest(env: RulesTestEnvironment, uid: string): RulesTestContext {
  return env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } });
}

export const serverTime = () => firebase.firestore.FieldValue.serverTimestamp();

export function inHours(hours: number): firebase.firestore.Timestamp {
  return firebase.firestore.Timestamp.fromMillis(Date.now() + hours * 60 * 60 * 1000);
}

/** An encrypted document as the app writes it: only the payload. */
export const encrypted = { payload: 'ciphertext' };

/**
 * Writes the household [householdId] with [admin] as its admin and every
 * one of [members] as a member, bypassing the rules. Each user's profile
 * names the household as active.
 */
export async function seedHousehold(
  env: RulesTestEnvironment,
  householdId: string,
  admin: string,
  members: string[] = [],
): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc(`households/${householdId}`).set({ created_at: new Date() });
    for (const [uid, role] of [[admin, 'admin'], ...members.map((uid) => [uid, 'member'])]) {
      await db.doc(`households/${householdId}/members/${uid}`).set({
        uid,
        role,
        joined_at: new Date(),
      });
      await db.doc(`users/${uid}`).set({ uid, householdId });
    }
  });
}
