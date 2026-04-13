const fs = require('node:fs');
const path = require('node:path');
const { before, after, afterEach, test } = require('node:test');

const shouldRun = process.env.RUN_FIRESTORE_RULES_TESTS === '1';
const maybeTest = shouldRun ? test : test.skip;

let initializeTestEnvironment;
let assertFails;
let assertSucceeds;
let doc;
let getDoc;
let setDoc;
let updateDoc;
let testEnv;

if (shouldRun) {
  ({
    initializeTestEnvironment,
    assertFails,
    assertSucceeds,
  } = require('@firebase/rules-unit-testing'));
  ({ doc, getDoc, setDoc, updateDoc } = require('firebase/firestore'));
}

const projectId = process.env.GCLOUD_PROJECT ?? 'demo-yamt';
const [emulatorHost, emulatorPortText = '8080'] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');

function rulesPath() {
  return path.resolve(__dirname, '../../firestore.rules');
}

function globalFoodItem({
  id,
  name,
  brand = null,
  normalizedBrand = null,
  nutrition = null,
  updatedAt = '2026-04-13T10:00:00.000Z',
}) {
  return {
    id,
    food_fingerprint: 'milk__fingerprint',
    name,
    brand,
    barcode: '4006381333931',
    image_url: null,
    package_weight: null,
    serving_size: null,
    serving_quantity: null,
    serving_quantity_unit: null,
    nutrition,
    normalized_name: 'milk',
    normalized_brand: normalizedBrand,
    normalized_store_name: null,
    search_tokens: ['milk'],
    status: 'active',
    merged_into_id: null,
    created_at: '2026-03-01T10:00:00.000Z',
    updated_at: updatedAt,
  };
}

function nutrition({ kcal = null, protein = null, quality = 'verified' } = {}) {
  return {
    quality_status: quality,
    per_100_kcal: kcal,
    per_100_protein: protein,
    per_100_carbs: null,
    per_100_fat: null,
    per_100_salt: null,
    per_100_saturated_fat: null,
    per_100_polyunsaturated_fat: null,
    per_100_sugar: null,
    per_100_fiber: null,
  };
}

function barcodeCandidate({
  id,
  globalFoodItem,
  selectionCount = 1,
  uniqueUserCount = 1,
  completenessScore = 8,
  updatedAt = '2026-04-13T10:00:00.000Z',
}) {
  return {
    id,
    barcode: '4006381333931',
    global_food_item_id: globalFoodItem.id,
    selection_count: selectionCount,
    unique_user_count: uniqueUserCount,
    completeness_score: completenessScore,
    global_food_item: globalFoodItem,
    created_at: '2026-03-01T10:00:00.000Z',
    updated_at: updatedAt,
  };
}

async function seedDocument(pathText, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await setDoc(doc(firestore, pathText), data);
  });
}

before(async () => {
  if (!shouldRun) {
    return;
  }
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: emulatorHost,
      port: Number.parseInt(emulatorPortText, 10),
      rules: fs.readFileSync(rulesPath(), 'utf8'),
    },
  });
});

afterEach(async () => {
  if (!shouldRun) {
    return;
  }
  await testEnv.clearFirestore();
});

after(async () => {
  if (!shouldRun) {
    return;
  }
  await testEnv.cleanup();
});

maybeTest(
  'global_food_items update denies overwriting existing identity fields',
  async () => {
    const item = globalFoodItem({
      id: 'milk',
      name: 'Milk',
      brand: 'Acme',
      normalizedBrand: 'acme',
      nutrition: nutrition({ kcal: 100 }),
    });
    await seedDocument('global_food_items/milk', item);

    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'global_food_items/milk'), {
        brand: 'Spam',
        normalized_brand: 'spam',
        updated_at: '2026-04-13T11:00:00.000Z',
      }),
    );
  },
);

maybeTest(
  'global_food_items update allows filling missing fields only',
  async () => {
    await seedDocument(
      'global_food_items/milk',
      globalFoodItem({
        id: 'milk',
        name: 'Milk',
      }),
    );

    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'global_food_items/milk'), {
        brand: 'Acme',
        normalized_brand: 'acme',
        nutrition: nutrition({ kcal: 100 }),
        updated_at: '2026-04-13T11:00:00.000Z',
      }),
    );

    const snapshot = await getDoc(doc(db, 'global_food_items/milk'));
    if (!snapshot.exists()) {
      throw new Error('Expected patched global food item to exist.');
    }
  },
);

maybeTest(
  'global_food_items update denies overwriting existing nutrition values',
  async () => {
    await seedDocument(
      'global_food_items/milk',
      globalFoodItem({
        id: 'milk',
        name: 'Milk',
        nutrition: nutrition({ kcal: 100 }),
      }),
    );

    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'global_food_items/milk'), {
        nutrition: nutrition({ kcal: 250 }),
        updated_at: '2026-04-13T11:00:00.000Z',
      }),
    );
  },
);

maybeTest(
  'global_barcode_candidates vote update denies payload rewrite',
  async () => {
    const item = globalFoodItem({
      id: 'milk',
      name: 'Milk',
      brand: 'Acme',
      normalizedBrand: 'acme',
      nutrition: nutrition({ kcal: 100 }),
    });
    await seedDocument(
      'global_barcode_candidates/barcode-4006381333931-milk',
      barcodeCandidate({
        id: 'barcode-4006381333931-milk',
        globalFoodItem: item,
        completenessScore: 10,
      }),
    );

    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'global_barcode_candidates/barcode-4006381333931-milk'), {
        selection_count: 2,
        unique_user_count: 2,
        completeness_score: 10,
        'global_food_item.name': 'Spam Milk',
        updated_at: '2026-04-13T11:00:00.000Z',
      }),
    );
  },
);

maybeTest(
  'global_barcode_candidates vote update allows counter-only change',
  async () => {
    const item = globalFoodItem({
      id: 'milk',
      name: 'Milk',
    });
    await seedDocument(
      'global_barcode_candidates/barcode-4006381333931-milk',
      barcodeCandidate({
        id: 'barcode-4006381333931-milk',
        globalFoodItem: item,
        completenessScore: 4,
      }),
    );

    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'global_barcode_candidates/barcode-4006381333931-milk'), {
        selection_count: 2,
        unique_user_count: 2,
        updated_at: '2026-04-13T11:00:00.000Z',
      }),
    );
  },
);
