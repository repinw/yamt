const test = require("node:test");
const assert = require("node:assert/strict");

const {
  scoreKeywordMatch,
  isKeywordMatchReliable,
  jaccardScore,
  countSetIntersection,
} = require("../../src/barcode_enrichment/global_catalog");
const {
  buildLookupKeywords,
} = require("../../src/barcode_enrichment/helpers");

test("jaccardScore returns expected intersection ratio", () => {
  const score = jaccardScore(["a", "b"], ["a", "c"]);
  assert.equal(score, 1 / 3);
});

test("countSetIntersection counts shared tokens", () => {
  const left = new Set(["a", "b", "c"]);
  const right = new Set(["b", "d", "c"]);
  assert.equal(countSetIntersection(left, right), 2);
});

test("scoreKeywordMatch is reliable for strong exact name/brand", () => {
  const match = scoreKeywordMatch({
    data: {
      itemName: "Haehnchenbrustfilet",
      brand: "Vom Land",
      keywords: [
        "haehnchenbrustfilet",
        "haehnchen",
        "brust",
        "filet",
        "vom",
        "land",
      ],
    },
    itemName: "Haehnchenbrustfilet",
    brand: "Vom Land",
    lookupKeywords: buildLookupKeywords({
      itemName: "Haehnchenbrustfilet",
      brand: "Vom Land",
      weight: null,
    }),
  });

  assert.equal(match.score >= 10, true);
  assert.equal(isKeywordMatchReliable(match), true);
});

test("scoreKeywordMatch rejects weak generic match", () => {
  const match = scoreKeywordMatch({
    data: {
      itemName: "Eier",
      brand: "Vom Land",
      keywords: ["eier", "land"],
    },
    itemName: "Bunte Eier",
    brand: "Vom Land",
    lookupKeywords: buildLookupKeywords({
      itemName: "Bunte Eier",
      brand: "Vom Land",
      weight: null,
    }),
  });

  assert.equal(isKeywordMatchReliable(match), false);
});
