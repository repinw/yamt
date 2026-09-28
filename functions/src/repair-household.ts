import type { Firestore } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';

import {
  FileStore,
  Logger,
  deleteHouseholdContent,
  deleteHouseholdInvites,
  toMember,
} from './delete-user-data';
import { HouseholdRepairPlan, planHouseholdRepair } from './household-plan';

const HOUSEHOLDS = 'households';
const MEMBERS = 'members';

/**
 * Keeps a household whole after a member document was deleted or changed its
 * role: a household without members is deleted with all its data and
 * invites, a household without an admin gets the member who joined first as
 * admin. Clients may not delete a household themselves: the rules cannot
 * count its members.
 *
 * Idempotent: every call recomputes the plan from the current documents.
 */
export async function repairHousehold(
  db: Firestore,
  files: FileStore,
  householdId: string,
  warn: Logger = () => undefined,
): Promise<HouseholdRepairPlan['kind']> {
  const household = db.collection(HOUSEHOLDS).doc(householdId);
  const plan = await settleAdmin(db, householdId);
  if (plan.kind !== 'delete-household') {
    return plan.kind;
  }

  // Delete the invites first, so nobody can join any more, and check again
  // that nobody joined in the meantime.
  await deleteHouseholdInvites(db, householdId);
  const checked = await settleAdmin(db, householdId);
  if (checked.kind !== 'delete-household') {
    return checked.kind;
  }
  await deleteHouseholdContent(db, files, household);

  // A member who joined right before the household document went keeps a
  // household, now empty, instead of a membership in nothing.
  const final = await settleAdmin(db, householdId);
  if (final.kind !== 'delete-household') {
    warn('A member joined a household during its deletion', { householdId });
    await household.set({ created_at: FieldValue.serverTimestamp() });
    return final.kind;
  }
  return 'delete-household';
}

/** Promotes a member in a transaction when no admin is left. */
async function settleAdmin(db: Firestore, householdId: string): Promise<HouseholdRepairPlan> {
  const members = db.collection(HOUSEHOLDS).doc(householdId).collection(MEMBERS);
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(members);
    const plan = planHouseholdRepair(snapshot.docs.map(toMember));
    if (plan.kind === 'promote') {
      tx.update(members.doc(plan.promoteUid), { role: 'admin' });
    }
    return plan;
  });
}
