import 'package:google_generative_ai/google_generative_ai.dart';

/// System prompt instruction for German receipt analysis.
const String googleAiReceiptSystemInstruction = '''
You are an expert receipt parser specialized in German supermarket receipts (REWE, EDEKA, Aldi, Lidl, Netto, Kaufland, dm, Rossmann, etc.).
Analyze the provided receipt text or PDF document and return a structured JSON object according to the schema.

Rules:
1. Extract store name (e.g. "REWE", "Aldi Süd", "Lidl").
2. Extract purchase date and time if visible (in ISO-8601 format like "2026-09-13T14:30:00").
3. Extract final printed total (Summe / Zu zahlen / Gesamtbetrag).
4. Extract all line items:
   - rawName: The exact product line text as printed.
   - totalPrice: The price printed on the right for this line (use negative number only if explicitly printed as negative/deduction, e.g. bottle deposit refund / Leergut).
   - discount: Direct item discount if listed on an adjacent line or marked with rabatt (positive number, 0.0 if none).
   - quantity: Purchased quantity (default 1.0, or weight in kg e.g. 0.450 if weighed).
   - unitPrice & unit: If indicated (e.g. 1.99 EUR/kg -> unitPrice: 1.99, unit: "kg").
   - rawBrand: Product brand or receipt abbreviation if recognizable (e.g. "SG GGN", "GL").
   - packageWeight: Package content, not purchased quantity (e.g. "200g", "1L", "2x125g").
   - isDeposit: true if this is bottle/crate deposit or refund (e.g. "PFAND", "LEERGUT", "EINWEGPFAND").
   - isDiscount: true if this is a general discount voucher/coupon line (e.g. "-5€ Coupon").
5. Deduplication: If overlapping photos contain repeating lines, merge them without duplicating items.
''';

/// Schema definition for structured receipt JSON output from Gemini Flash.
final Schema googleAiReceiptSchema = Schema.object(
  properties: {
    'storeName': Schema.string(
      description: 'Name of the supermarket or store',
      nullable: true,
    ),
    'dateTime': Schema.string(
      description: 'ISO-8601 timestamp of purchase',
      nullable: true,
    ),
    'printedTotal': Schema.number(
      description: 'Final printed total amount on receipt',
      nullable: true,
    ),
    'currency': Schema.string(
      description: 'Currency code, usually EUR',
      nullable: true,
    ),
    'items': Schema.array(
      description: 'All purchased products and items',
      items: Schema.object(
        properties: {
          'rawName': Schema.string(
            description: 'Original product name text as printed on receipt',
          ),
          'totalPrice': Schema.number(
            description: 'Price printed for this line before item discounts',
          ),
          'discount': Schema.number(
            description: 'Direct discount amount deducted from item, 0 if none',
            nullable: true,
          ),
          'quantity': Schema.number(
            description: 'Quantity bought (default 1.0, or weight in kg)',
            nullable: true,
          ),
          'unitPrice': Schema.number(
            description: 'Unit price per kg or piece if indicated',
            nullable: true,
          ),
          'unit': Schema.string(
            description: 'Unit of measurement (e.g. kg, g, l, Stk)',
            nullable: true,
          ),
          'rawCategory': Schema.string(
            description: 'Department or category name if printed',
            nullable: true,
          ),
          'rawBrand': Schema.string(
            description: 'Product brand or abbreviated receipt brand marker',
            nullable: true,
          ),
          'packageWeight': Schema.string(
            description: 'Package content such as 200g, 1L, or 2x125g',
            nullable: true,
          ),
          'isDeposit': Schema.boolean(
            description: 'True if this is a bottle/crate deposit (Pfand) line',
            nullable: true,
          ),
          'isDiscount': Schema.boolean(
            description: 'True if this is a coupon or voucher deduction line',
            nullable: true,
          ),
        },
        requiredProperties: ['rawName', 'totalPrice'],
      ),
    ),
  },
  requiredProperties: ['items'],
);
