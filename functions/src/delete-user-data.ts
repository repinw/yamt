import type {
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  Firestore,
} from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';

import { HouseholdExitPlan, HouseholdMember, planHouseholdExit } from './household-plan';

/** Deletes every Storage file under a path prefix and returns how many it deleted. */
export interface FileStore {
  deletePrefix(prefix: string): Promise<number>;
}

/** Counts for the log line; never contents. */
export interface DeletionSummary {
  householdsLeft: number;
  householdsDeleted: number;
  adminsPromoted: number;
  invitesDeleted: number;
  firestoreDeletes: number;
  storageFilesDeleted: number;
}

export type Logger = (message: string, details: Record<string, unknown>) => void;

const HOUSEHOLDS = 'households';
const MEMBERS = 'members';
const KEYS = 'keys';
const KEY_RESTORES = 'key_restores';
const HOUSEHOLD_INVITES = 'household_invites';
const USERS = 'users';

/**
 * Removes all data of a deleted account.
 *
 * Idempotent: every step either deletes what still exists or recomputes its
 * plan from the current documents. A sole member's `members/{uid}` document
 * is deleted only after the rest of the household is gone, so a retry after
 * a crash still finds the household. `users/{uid}` goes last.
 */
export async function deleteUserData(
  db: Firestore,
  files: FileStore,
  uid: string,
  warn: Logger = () => undefined,
): Promise<DeletionSummary> {
  if (!uid) {
    throw new Error('deleteUserData needs a uid');
  }
  const summary: DeletionSummary = {
    householdsLeft: 0,
    householdsDeleted: 0,
    adminsPromoted: 0,
    invitesDeleted: 0,
    firestoreDeletes: 0,
    storageFilesDeleted: 0,
  };

  for (const householdId of await findHouseholdIds(db, uid)) {
    await exitHousehold(db, files, householdId, uid, summary, warn);
  }

  summary.firestoreDeletes += await recursiveDeleteCounted(db, db.collection(USERS).doc(uid));
  summary.storageFilesDeleted += await files.deletePrefix(`${USERS}/${uid}/`);
  return summary;
}

/**
 * Households of the user: every `households/{hid}/members` document with
 * this uid. The household ids on the profile are ignored on purpose: the user
 * writes them, so a forged id could point this admin code at someone else's
 * household.
 */
async function findHouseholdIds(db: Firestore, uid: string): Promise<string[]> {
  const ids = new Set<string>();
  const memberships = await db.collectionGroup(MEMBERS).where('uid', '==', uid).get();
  for (const doc of memberships.docs) {
    const householdId = householdIdOfMember(doc.ref);
    if (householdId !== null) {
      ids.add(householdId);
    }
  }
  return [...ids].sort();
}

/** `households/{hid}/members/{uid}` gives hid; a `members` collection anywhere else gives null. */
function householdIdOfMember(ref: DocumentReference): string | null {
  const household = ref.parent.parent;
  if (household === null) {
    return null;
  }
  const households = household.parent;
  if (households.id !== HOUSEHOLDS || households.parent !== null) {
    return null;
  }
  return household.id;
}

async function exitHousehold(
  db: Firestore,
  files: FileStore,
  householdId: string,
  uid: string,
  summary: DeletionSummary,
  warn: Logger,
): Promise<void> {
  const household = db.collection(HOUSEHOLDS).doc(householdId);

  const plan = await settleMembership(db, household, uid, false);
  if (plan.kind === 'skip') {
    return;
  }
  if (plan.kind === 'leave') {
    countLeave(plan, summary);
    return;
  }

  // Sole member: delete the invites first, so nobody can join any more, and
  // check again that nobody joined in the meantime.
  summary.invitesDeleted += await deleteHouseholdInvites(db, householdId);
  const checkedPlan = await settleMembership(db, household, uid, false);
  if (checkedPlan.kind === 'skip') {
    return;
  }
  if (checkedPlan.kind === 'leave') {
    countLeave(checkedPlan, summary);
    return;
  }

  // Then delete everything but the member documents.
  const deleted = await deleteHouseholdContent(db, files, household);
  summary.storageFilesDeleted += deleted.storageFilesDeleted;
  summary.firestoreDeletes += deleted.firestoreDeletes;

  const finalPlan = await settleMembership(db, household, uid, true);
  if (finalPlan.kind === 'leave') {
    // Someone joined while the household was being deleted; keep that member.
    warn('A member joined a household during its deletion', { householdId });
    countLeave(finalPlan, summary);
    return;
  }
  summary.householdsDeleted += 1;
}

/** Deletes the invites into `householdId` and returns how many it deleted. */
export async function deleteHouseholdInvites(db: Firestore, householdId: string): Promise<number> {
  const invites = await db.collection(HOUSEHOLD_INVITES).where('householdId', '==', householdId).get();
  return deleteDocsCounted(
    db,
    invites.docs.map((doc) => doc.ref),
  );
}

/**
 * Deletes the images, the household document and every subcollection but
 * `members`, so a retry still finds who was in the household.
 */
export async function deleteHouseholdContent(
  db: Firestore,
  files: FileStore,
  household: DocumentReference,
): Promise<{ firestoreDeletes: number; storageFilesDeleted: number }> {
  const storageFilesDeleted = await files.deletePrefix(`${HOUSEHOLDS}/${household.id}/`);
  let firestoreDeletes = 0;
  for (const collection of await household.listCollections()) {
    if (collection.id !== MEMBERS) {
      firestoreDeletes += await recursiveDeleteCounted(db, collection);
    }
  }
  await household.delete();
  firestoreDeletes += 1;
  return { firestoreDeletes, storageFilesDeleted };
}

/**
 * Reads all members in a transaction and applies the plan's member writes in
 * the same transaction, so two accounts deleted at the same time cannot both
 * leave without handing the admin role on.
 *
 * With `contentDeleted` false a sole member's documents stay untouched; with
 * true the remaining member documents are deleted as the household's last
 * step.
 */
async function settleMembership(
  db: Firestore,
  household: DocumentReference,
  uid: string,
  contentDeleted: boolean,
): Promise<HouseholdExitPlan> {
  const members = household.collection(MEMBERS);
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(members);
    const plan = planHouseholdExit(snapshot.docs.map(toMember), uid);
    if (plan.kind === 'leave') {
      tx.delete(members.doc(uid));
      tx.delete(household.collection(KEYS).doc(uid));
      tx.delete(household.collection(KEY_RESTORES).doc(uid));
      if (plan.promoteUid !== null) {
        tx.update(members.doc(plan.promoteUid), { role: 'admin' });
      }
    } else if (plan.kind === 'delete-household' && contentDeleted) {
      for (const doc of snapshot.docs) {
        tx.delete(doc.ref);
      }
    }
    return plan;
  });
}

export function toMember(doc: DocumentSnapshot): HouseholdMember {
  const role: unknown = doc.get('role');
  const joinedAt: unknown = doc.get('joined_at');
  return {
    uid: doc.id,
    role: typeof role === 'string' ? role : '',
    joinedAtMillis: joinedAt instanceof Timestamp ? joinedAt.toMillis() : null,
  };
}

function countLeave(plan: { promoteUid: string | null }, summary: DeletionSummary): void {
  summary.householdsLeft += 1;
  if (plan.promoteUid !== null) {
    summary.adminsPromoted += 1;
  }
}

async function recursiveDeleteCounted(
  db: Firestore,
  ref: DocumentReference | CollectionReference,
): Promise<number> {
  const writer = db.bulkWriter();
  let deleted = 0;
  writer.onWriteResult(() => {
    deleted += 1;
  });
  try {
    await db.recursiveDelete(ref, writer);
  } finally {
    await writer.close();
  }
  return deleted;
}

const MAX_BATCH_WRITES = 500;

async function deleteDocsCounted(db: Firestore, refs: DocumentReference[]): Promise<number> {
  for (let start = 0; start < refs.length; start += MAX_BATCH_WRITES) {
    const batch = db.batch();
    for (const ref of refs.slice(start, start + MAX_BATCH_WRITES)) {
      batch.delete(ref);
    }
    await batch.commit();
  }
  return refs.length;
}
