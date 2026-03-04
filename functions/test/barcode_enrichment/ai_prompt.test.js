const test = require("node:test");
const assert = require("node:assert/strict");

const { buildSinglePrompt } = require("../../src/barcode_enrichment/ai");

test("buildSinglePrompt includes all resolver inputs", () => {
  const prompt = buildSinglePrompt({
    itemName: "Bunte Eier",
    brand: "Vom Land",
    storeName: "Kaufland",
    weight: "10 Stk",
  });

  assert.match(prompt, /item_name: "Bunte Eier"/);
  assert.match(prompt, /brand: "Vom Land"/);
  assert.match(prompt, /store_name: "Kaufland"/);
  assert.match(prompt, /weight: "10 Stk"/);
});

test("buildSinglePrompt asks for JSON and active web search", () => {
  const prompt = buildSinglePrompt({
    itemName: "Thunfisch",
    brand: "MSC",
    storeName: null,
    weight: null,
  });

  assert.match(prompt, /Nutze Websuche aktiv\./);
  assert.match(prompt, /Gib nur JSON zurueck\./);
  assert.match(prompt, /"ean_candidates"/);
});
