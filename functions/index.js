const { onCall } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const {
  resolveInventoryItemBarcodeOptions,
  enqueueInventoryBarcodeJobsOptions,
  onBarcodeEnrichmentJobWrittenOptions,
  resolveInventoryItemBarcodeHandler,
  enqueueInventoryBarcodeJobsHandler,
  onBarcodeEnrichmentJobWrittenHandler,
} = require("./src/barcode_enrichment/handlers");
const {
  resolveOffProductByBarcodeOptions,
  resolveOffProductByBarcodeHandler,
} = require("./src/off_lookup/handlers");

exports.resolveInventoryItemBarcode = onCall(
  resolveInventoryItemBarcodeOptions,
  resolveInventoryItemBarcodeHandler,
);

exports.enqueueInventoryBarcodeJobs = onCall(
  enqueueInventoryBarcodeJobsOptions,
  enqueueInventoryBarcodeJobsHandler,
);

exports.onBarcodeEnrichmentJobWritten = onDocumentWritten(
  onBarcodeEnrichmentJobWrittenOptions,
  onBarcodeEnrichmentJobWrittenHandler,
);

exports.resolveOffProductByBarcode = onCall(
  resolveOffProductByBarcodeOptions,
  resolveOffProductByBarcodeHandler,
);
