import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import * as functions from 'firebase-functions/v1';

import { bucketFileStore } from './bucket-file-store';
import { deleteUserData } from './delete-user-data';

initializeApp();

/**
 * Deletes a user's private data, household memberships and sole-member
 * households when the Firebase Auth user is deleted (account deletion and
 * the account-link conflict paths). Global catalog contributions stay.
 *
 * v1 trigger: v2 has no plain Auth delete trigger. europe-west1 sits in the
 * eur3 multi-region of the Firestore database. Retries are on because every
 * step is idempotent.
 */
export const deleteAccountData = functions
  .region('europe-west1')
  .runWith({ failurePolicy: true, timeoutSeconds: 540, memory: '256MB' })
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    try {
      const summary = await deleteUserData(
        getFirestore(),
        bucketFileStore(getStorage().bucket()),
        uid,
        (message, details) => functions.logger.warn(message, { uid, ...details }),
      );
      functions.logger.info('Deleted the data of a deleted account', { uid, ...summary });
    } catch (error) {
      functions.logger.error('Deleting the data of a deleted account failed; retrying', {
        uid,
        error: error instanceof Error ? error.message : String(error),
      });
      throw error;
    }
  });
