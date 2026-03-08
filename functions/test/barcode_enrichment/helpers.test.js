const test = require("node:test");
const assert = require("node:assert/strict");

const {
  tokenizeForLookup,
  buildLookupKeywords,
  parseResponseAsJson,
  isResourceExhaustedError,
  normalizeCandidates,
} = require("../../src/barcode_enrichment/helpers");

test("tokenizeForLookup expands aliases and compounds", () => {
  const tokens = tokenizeForLookup("Haehnchenbrustfilet");

  assert.equal(tokens.includes("haehnchen"), true);
  assert.equal(tokens.includes("brust"), true);
  assert.equal(tokens.includes("filet"), true);
});

test("tokenizeForLookup maps aliases like haehn/brst", () => {
  const tokens = tokenizeForLookup("Haehn brst");

  assert.equal(tokens.includes("haehnchen"), true);
  assert.equal(tokens.includes("brust"), true);
});

test("tokenizeForLookup removes stopwords", () => {
  const tokens = tokenizeForLookup("Eier vom Land");

  assert.equal(tokens.includes("vom"), false);
  assert.equal(tokens.includes("land"), false);
  assert.equal(tokens.includes("eier"), true);
});

test("buildLookupKeywords returns normalized phrase and tokens", () => {
  const keywords = buildLookupKeywords({
    itemName: "Hähnchenbrustfilet",
    brand: "Vom Land",
    weight: "500 g",
  });

  assert.equal(keywords.includes("haehnchenbrustfilet"), true);
  assert.equal(keywords.includes("haehnchen"), true);
  assert.equal(keywords.includes("brust"), true);
  assert.equal(keywords.includes("filet"), true);
});

test("normalizeCandidates keeps unique valid EANs", () => {
  const normalized = normalizeCandidates([
    "4316268648998",
    "4316268648998",
    "invalid",
    "42261964",
  ]);

  assert.deepEqual(normalized, ["4316268648998", "42261964"]);
});

test("parseResponseAsJson reads direct JSON field", () => {
  const parsed = parseResponseAsJson({
    ean_candidates: ["4316268648998"],
  });

  assert.deepEqual(parsed, {
    ean_candidates: ["4316268648998"],
  });
});

test("parseResponseAsJson keeps uncertainty from direct JSON field", () => {
  const parsed = parseResponseAsJson({
    ean_candidates: ["4316268648998"],
    is_uncertain: true,
  });

  assert.deepEqual(parsed, {
    ean_candidates: ["4316268648998"],
    is_uncertain: true,
  });
});

test("parseResponseAsJson extracts JSON from text response", () => {
  const parsed = parseResponseAsJson({
    text:
      "Result:\n" +
      '{ "ean_candidates": ["4316268648998", "42261964"] }',
  });

  assert.deepEqual(parsed, {
    ean_candidates: ["4316268648998", "42261964"],
  });
});

test("parseResponseAsJson returns null for unexpected HTML payload", () => {
  const parsed = parseResponseAsJson({
    text: "<!DOCTYPE html><html><body>error</body></html>",
  });

  assert.equal(parsed, null);
});

test("isResourceExhaustedError detects 429 and resource exhausted", () => {
  assert.equal(isResourceExhaustedError({ code: 429 }), true);
  assert.equal(
    isResourceExhaustedError({ message: "RESOURCE_EXHAUSTED by quota" }),
    true,
  );
  assert.equal(
    isResourceExhaustedError({ cause: { message: "HTTP 429 from upstream" } }),
    true,
  );
  assert.equal(isResourceExhaustedError({ message: "network timeout" }), false);
});
