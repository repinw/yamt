import type { getStorage } from 'firebase-admin/storage';

import type { FileStore } from './delete-user-data';

type Bucket = ReturnType<ReturnType<typeof getStorage>['bucket']>;

const PARALLEL_DELETES = 20;

/** A FileStore on a Cloud Storage bucket. Files that are already gone count as deleted. */
export function bucketFileStore(bucket: Bucket): FileStore {
  return {
    async deletePrefix(prefix: string): Promise<number> {
      if (!prefix.endsWith('/')) {
        throw new Error(`Storage prefix must end with '/': ${prefix}`);
      }
      const [files] = await bucket.getFiles({ prefix });
      for (let start = 0; start < files.length; start += PARALLEL_DELETES) {
        await Promise.all(
          files
            .slice(start, start + PARALLEL_DELETES)
            .map((file) => file.delete({ ignoreNotFound: true })),
        );
      }
      return files.length;
    },
  };
}
