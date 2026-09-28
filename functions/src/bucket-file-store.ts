import type { getStorage } from 'firebase-admin/storage';

import type { FileStore } from './delete-user-data';

type Bucket = ReturnType<ReturnType<typeof getStorage>['bucket']>;

const PARALLEL_DELETES = 20;
const PAGE_SIZE = 500;

/**
 * A FileStore on a Cloud Storage bucket. Files that are already gone count as
 * deleted. It lists one page at a time and deletes it before listing again,
 * so a big prefix never sits in memory at once.
 */
export function bucketFileStore(bucket: Bucket): FileStore {
  return {
    async deletePrefix(prefix: string): Promise<number> {
      if (!prefix.endsWith('/')) {
        throw new Error(`Storage prefix must end with '/': ${prefix}`);
      }
      let deleted = 0;
      for (;;) {
        const [files] = await bucket.getFiles({
          prefix,
          autoPaginate: false,
          maxResults: PAGE_SIZE,
        });
        if (files.length === 0) {
          return deleted;
        }
        for (let start = 0; start < files.length; start += PARALLEL_DELETES) {
          await Promise.all(
            files
              .slice(start, start + PARALLEL_DELETES)
              .map((file) => file.delete({ ignoreNotFound: true })),
          );
        }
        deleted += files.length;
      }
    },
  };
}
