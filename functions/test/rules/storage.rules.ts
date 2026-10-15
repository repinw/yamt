import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  RulesTestContext,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

import { account, rulesEnvironment, seedHousehold } from './rules-env';

let env: RulesTestEnvironment;

before(async () => {
  env = await rulesEnvironment();
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seedHousehold(env, 'h1', 'ada', ['bob']);
  await seedHousehold(env, 'h2', 'dora');
});

const jpeg = 'image/jpeg';

/** Uploads a few bytes of [contentType] to [path] as [context]. */
async function upload(
  context: RulesTestContext,
  path: string,
  contentType = jpeg,
  size = 4,
): Promise<void> {
  await context.storage().ref(path).put(new Uint8Array(size), { contentType });
}

const megabytes = (count: number) => count * 1024 * 1024;

/** Puts a file at [path] past the rules. */
async function seedFile(path: string): Promise<void> {
  await env.withSecurityRulesDisabled((context) => upload(context, path));
}

const read = (context: RulesTestContext, path: string) =>
  context.storage().ref(path).getMetadata();

const remove = (context: RulesTestContext, path: string) =>
  context.storage().ref(path).delete();

const list = (context: RulesTestContext, path: string) =>
  context.storage().ref(path).listAll();

describe('household images', () => {
  for (const path of [
    'households/h1/kitchen_utensils/u1/images/a.jpg',
    'households/h1/recipes/m1/images/a.jpg',
  ]) {
    describe(path, () => {
      it('lets a member upload, read and delete an image', async () => {
        const bob = account(env, 'bob');
        await assertSucceeds(upload(bob, path));
        await assertSucceeds(read(bob, path));
        await assertSucceeds(remove(bob, path));
      });

      it('refuses a file that is no image', async () => {
        await assertFails(upload(account(env, 'bob'), path, 'text/plain'));
      });

      it('keeps another household out', async () => {
        await seedFile(path);
        const dora = account(env, 'dora');
        await assertFails(read(dora, path));
        await assertFails(upload(dora, path));
        await assertFails(remove(dora, path));
      });
    });
  }

  it('limits utensil images to 2 MB and recipe images to 5 MB', async () => {
    const bob = account(env, 'bob');
    const utensil = 'households/h1/kitchen_utensils/u1/images/big.jpg';
    const recipe = 'households/h1/recipes/m1/images/big.jpg';
    await assertFails(upload(bob, utensil, jpeg, megabytes(2)));
    await assertSucceeds(upload(bob, recipe, jpeg, megabytes(3)));
    await assertFails(upload(bob, recipe, jpeg, megabytes(5)));
  });

  it('lets a member list the household image folders, not others', async () => {
    const bob = account(env, 'bob');
    await assertSucceeds(list(bob, 'households/h1/kitchen_utensils'));
    await assertSucceeds(list(bob, 'households/h1/recipes'));
    await assertFails(list(bob, 'households/h1/other'));
    await assertFails(list(account(env, 'dora'), 'households/h1/recipes'));
  });
});

describe('food photos of a user', () => {
  const path = 'users/ada/food_photos/plate.jpg';

  it('lets the owner upload, read and delete a photo', async () => {
    const ada = account(env, 'ada');
    await assertSucceeds(upload(ada, path));
    await assertSucceeds(read(ada, path));
    await assertSucceeds(remove(ada, path));
  });

  it("lets a member of the owner's household read it", async () => {
    await seedFile(path);
    await assertSucceeds(read(account(env, 'bob'), path));
  });

  it('keeps everybody else out and lets nobody else write', async () => {
    await seedFile(path);
    await assertFails(read(account(env, 'dora'), path));
    const bob = account(env, 'bob');
    await assertFails(upload(bob, 'users/ada/food_photos/other.jpg'));
    await assertFails(remove(bob, path));
  });

  it('refuses a file that is no image, or too big', async () => {
    const ada = account(env, 'ada');
    await assertFails(upload(ada, path, 'text/plain'));
    await assertFails(upload(ada, path, jpeg, megabytes(2)));
  });
});

describe('progress photos of a user', () => {
  const path = 'users/ada/progress_photos/p1';
  const sealed = 'application/octet-stream';

  it('lets the owner upload, read, list and delete a sealed photo', async () => {
    const ada = account(env, 'ada');
    await assertSucceeds(upload(ada, path, sealed));
    await assertSucceeds(read(ada, path));
    await assertSucceeds(list(ada, 'users/ada/progress_photos'));
    await assertSucceeds(remove(ada, path));
  });

  it('refuses a plain image and a file of 2 MB or more', async () => {
    const ada = account(env, 'ada');
    await assertFails(upload(ada, path, jpeg));
    await assertFails(upload(ada, path, sealed, megabytes(2)));
  });

  it('keeps a co-member and a stranger out', async () => {
    await env.withSecurityRulesDisabled((context) => upload(context, path, sealed));
    for (const uid of ['bob', 'dora']) {
      const other = account(env, uid);
      await assertFails(read(other, path));
      await assertFails(list(other, 'users/ada/progress_photos'));
      await assertFails(upload(other, 'users/ada/progress_photos/p2', sealed));
      await assertFails(remove(other, path));
    }
  });
});

describe('product images', () => {
  const path = 'product_images/ada/p1/front.jpg';

  it('lets the uploader add a photo to their own folder only', async () => {
    await assertSucceeds(upload(account(env, 'ada'), path));
    await assertFails(upload(account(env, 'bob'), 'product_images/ada/p2/front.jpg'));
  });

  it('refuses a product photo of 2 MB or more', async () => {
    const ada = account(env, 'ada');
    await assertFails(upload(ada, 'product_images/ada/p2/front.jpg', jpeg, megabytes(2)));
  });

  it('shows the photo to every signed-in user, and nobody deletes it', async () => {
    await seedFile(path);
    await assertSucceeds(read(account(env, 'dora'), path));
    await assertFails(remove(account(env, 'ada'), path));
    await assertFails(read(env.unauthenticatedContext(), path));
  });
});
