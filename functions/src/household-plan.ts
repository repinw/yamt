/**
 * Pure planning for what happens to a household when one of its members
 * deletes the account. No Firestore access here, so it is unit tested
 * without an emulator.
 */

export const ADMIN_ROLE = 'admin';

/** A document of `households/{hid}/members/{uid}`, reduced to what planning needs. */
export interface HouseholdMember {
  uid: string;
  /** 'admin' or 'member'; any other value counts as a plain member. */
  role: string;
  /** `joined_at` in milliseconds, or null when the field is missing. */
  joinedAtMillis: number | null;
}

export type HouseholdExitPlan =
  /** Nobody else is left: delete the household with all its data. */
  | { kind: 'delete-household' }
  /**
   * Others stay: remove the deleted user's member, key and key restore
   * documents; promote `promoteUid` to admin when no admin would remain.
   */
  | { kind: 'leave'; promoteUid: string | null }
  /** The user is not a member and others remain: nothing to do. */
  | { kind: 'skip' };

/**
 * Decides what to do with one household when `deletedUid` is deleted.
 *
 * `members` are all current member documents of the household. A household
 * without any other member is deleted, even when the deleted user is no
 * longer listed (an interrupted earlier run, or an own household without a
 * member document). When others remain and none of them is admin, the member
 * who joined first becomes admin. This covers the deleted admin and also two
 * accounts deleted at the same time.
 */
export function planHouseholdExit(
  members: readonly HouseholdMember[],
  deletedUid: string,
): HouseholdExitPlan {
  const remaining = members.filter((member) => member.uid !== deletedUid);
  if (remaining.length === 0) {
    return { kind: 'delete-household' };
  }
  if (remaining.length === members.length) {
    return { kind: 'skip' };
  }
  if (remaining.some((member) => member.role === ADMIN_ROLE)) {
    return { kind: 'leave', promoteUid: null };
  }
  return { kind: 'leave', promoteUid: longestMember(remaining).uid };
}

/**
 * The member who joined first. A missing `joined_at` sorts last; equal
 * times fall back to the uid so the choice is stable across retries.
 */
export function longestMember(members: readonly HouseholdMember[]): HouseholdMember {
  if (members.length === 0) {
    throw new Error('longestMember needs at least one member');
  }
  return [...members].sort(compareByJoinedAt)[0];
}

function compareByJoinedAt(a: HouseholdMember, b: HouseholdMember): number {
  const aJoined = a.joinedAtMillis ?? Number.POSITIVE_INFINITY;
  const bJoined = b.joinedAtMillis ?? Number.POSITIVE_INFINITY;
  if (aJoined !== bJoined) {
    return aJoined < bJoined ? -1 : 1;
  }
  if (a.uid === b.uid) {
    return 0;
  }
  return a.uid < b.uid ? -1 : 1;
}

export type HouseholdRepairPlan =
  /** Nobody is left: delete the household with all its data. */
  | { kind: 'delete-household' }
  /** Members are left but no admin: `promoteUid` becomes admin. */
  | { kind: 'promote'; promoteUid: string }
  /** Members and an admin are left: nothing to do. */
  | { kind: 'none' };

/**
 * Decides what a household needs after one of its member documents was
 * deleted or changed its role. The app never leaves a household without an
 * admin or with no member, but a client that talks to Firestore directly
 * can; this puts it right.
 */
export function planHouseholdRepair(members: readonly HouseholdMember[]): HouseholdRepairPlan {
  if (members.length === 0) {
    return { kind: 'delete-household' };
  }
  if (members.some((member) => member.role === ADMIN_ROLE)) {
    return { kind: 'none' };
  }
  return { kind: 'promote', promoteUid: longestMember(members).uid };
}
