import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  HouseholdMember,
  longestMember,
  planHouseholdExit,
  planHouseholdRepair,
} from '../src/household-plan';

function member(uid: string, role: string, joinedAtMillis: number | null): HouseholdMember {
  return { uid, role, joinedAtMillis };
}

/** Applies a plan the way the transaction does, for multi-step scenarios. */
function apply(members: HouseholdMember[], deletedUid: string): HouseholdMember[] {
  const plan = planHouseholdExit(members, deletedUid);
  if (plan.kind === 'delete-household') {
    return [];
  }
  if (plan.kind === 'skip') {
    return members;
  }
  return members
    .filter((m) => m.uid !== deletedUid)
    .map((m) => (m.uid === plan.promoteUid ? { ...m, role: 'admin' } : m));
}

describe('planHouseholdExit', () => {
  it('deletes the household of a sole member', () => {
    assert.deepEqual(planHouseholdExit([member('u', 'admin', 1)], 'u'), {
      kind: 'delete-household',
    });
  });

  it('deletes a household without any member (interrupted run, orphaned own household)', () => {
    assert.deepEqual(planHouseholdExit([], 'u'), { kind: 'delete-household' });
  });

  it('promotes the member who joined first when the admin leaves', () => {
    const members = [
      member('admin', 'admin', 1),
      member('late', 'member', 300),
      member('early', 'member', 200),
    ];
    assert.deepEqual(planHouseholdExit(members, 'admin'), { kind: 'leave', promoteUid: 'early' });
  });

  it('keeps the admin when a plain member leaves', () => {
    const members = [member('admin', 'admin', 1), member('m', 'member', 2), member('n', 'member', 3)];
    assert.deepEqual(planHouseholdExit(members, 'm'), { kind: 'leave', promoteUid: null });
  });

  it('promotes nobody when another admin remains', () => {
    const members = [member('a', 'admin', 1), member('b', 'admin', 5), member('c', 'member', 2)];
    assert.deepEqual(planHouseholdExit(members, 'a'), { kind: 'leave', promoteUid: null });
  });

  it('promotes when a member leaves and no admin is left', () => {
    const members = [member('m', 'member', 2), member('n', 'member', 3)];
    assert.deepEqual(planHouseholdExit(members, 'm'), { kind: 'leave', promoteUid: 'n' });
  });

  it('skips a household the user is not a member of', () => {
    const members = [member('a', 'admin', 1), member('b', 'member', 2)];
    assert.deepEqual(planHouseholdExit(members, 'gone'), { kind: 'skip' });
  });

  it('treats an unknown role as a plain member', () => {
    const members = [member('a', 'admin', 1), member('b', 'owner', 2)];
    assert.deepEqual(planHouseholdExit(members, 'a'), { kind: 'leave', promoteUid: 'b' });
  });

  it('leaves an admin after two accounts are deleted one after the other', () => {
    const start = [
      member('a', 'admin', 1),
      member('b', 'member', 2),
      member('c', 'member', 3),
    ];
    assert.deepEqual(apply(apply(start, 'a'), 'b'), [member('c', 'admin', 3)]);
    assert.deepEqual(apply(apply(start, 'b'), 'a'), [member('c', 'admin', 3)]);
  });

  it('deletes the household when the last two members are deleted one after the other', () => {
    const start = [member('a', 'admin', 1), member('b', 'member', 2)];
    const afterA = apply(start, 'a');
    assert.deepEqual(afterA, [member('b', 'admin', 2)]);
    assert.deepEqual(planHouseholdExit(afterA, 'b'), { kind: 'delete-household' });
  });

  it('gives the same answer on a retry after the user already left', () => {
    const start = [member('a', 'admin', 1), member('b', 'member', 2)];
    const afterA = apply(start, 'a');
    assert.deepEqual(planHouseholdExit(afterA, 'a'), { kind: 'skip' });
  });
});

describe('longestMember', () => {
  it('picks the earliest joined_at', () => {
    const members = [member('x', 'member', 30), member('y', 'member', 10), member('z', 'member', 20)];
    assert.equal(longestMember(members).uid, 'y');
  });

  it('breaks a tie by uid', () => {
    const members = [member('b', 'member', 10), member('a', 'member', 10)];
    assert.equal(longestMember(members).uid, 'a');
  });

  it('sorts a missing joined_at last', () => {
    const members = [member('a', 'member', null), member('b', 'member', 99)];
    assert.equal(longestMember(members).uid, 'b');
  });

  it('breaks a tie of missing joined_at by uid', () => {
    const members = [member('b', 'member', null), member('a', 'member', null)];
    assert.equal(longestMember(members).uid, 'a');
  });

  it('does not reorder its input', () => {
    const members = [member('x', 'member', 30), member('y', 'member', 10)];
    longestMember(members);
    assert.deepEqual(
      members.map((m) => m.uid),
      ['x', 'y'],
    );
  });

  it('throws without members', () => {
    assert.throws(() => longestMember([]));
  });
});

describe('planHouseholdRepair', () => {
  it('deletes a household without members', () => {
    assert.deepEqual(planHouseholdRepair([]), { kind: 'delete-household' });
  });

  it('leaves a household with an admin alone', () => {
    const members = [member('a', 'admin', 1), member('m', 'member', 2)];
    assert.deepEqual(planHouseholdRepair(members), { kind: 'none' });
  });

  it('promotes the member who joined first when no admin is left', () => {
    const members = [member('late', 'member', 9), member('early', 'member', 2)];
    assert.deepEqual(planHouseholdRepair(members), { kind: 'promote', promoteUid: 'early' });
  });
});
