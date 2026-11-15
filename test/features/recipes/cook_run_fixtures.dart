import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// A local start time with microseconds, to prove they survive the round
/// trip. Firestore hands dates back as local time.
final cookRunStart = DateTime(2026, 11, 7, 12, 30, 15, 123, 456);

const cookPotA = CookPot(
  id: 'pot-a',
  name: 'Topf',
  emptyWeight: 900,
  imageStoragePath: 'households/h/pot-a.jpg',
);

const cookPotB = CookPot(
  id: 'pot-b',
  name: null,
  emptyWeight: 600,
  imageStoragePath: null,
);

CookRunLine cookLine(
  String id, {
  LineSettlement settlement = const LineOpen(),
  CookLineOrigin origin = CookLineOrigin.recipe,
  int? amount,
  int? amountPortions,
  int? weighed,
  String? potId,
  CookLineConversion? conversion,
  List<String> addedItemIds = const [],
}) => CookRunLine(
  id: id,
  text: 'text $id',
  origin: origin,
  conversion: conversion,
  amount: amount,
  amountPortions: amount == null ? null : amountPortions ?? 4,
  amountUnit: null,
  settlement: settlement,
  weighed: weighed,
  potId: potId,
  addedItemIds: addedItemIds,
);

CookRun buildCookRun({
  String id = 'recipe-t1',
  String recipeId = 't1',
  CookRunStep step = CookRunStep.assign,
  List<CookRunLine>? lines,
  CookPotChoice? pots,
  List<String> steps = const ['one', 'two', 'three'],
  List<CookTimer> timers = const [],
  List<CookMealDraft> meals = const [],
  DateTime? startedAt,
  int portions = 4,
  List<String> droppedItemIds = const [],
}) => CookRun(
  id: id,
  kind: CookRunKind.recipe,
  step: step,
  recipeId: recipeId,
  name: 'Eintopf',
  imageAssetId: null,
  imageUrl: 'https://example.test/a.jpg',
  basePortions: 4,
  portions: portions,
  steps: steps,
  startedBy: 'uid-1',
  startedByName: 'Ada',
  startedAt: startedAt ?? cookRunStart,
  lines: lines ?? [cookLine('line-0'), cookLine('line-1')],
  pots: pots,
  withGuide: false,
  guideStep: 0,
  timers: timers,
  meals: meals,
  toCookbook: false,
  droppedItemIds: droppedItemIds,
);

/// A run that uses every type: all settlements, both pot kinds' parts,
/// a conversion, a timer and a meal draft.
CookRun fullCookRun() => buildCookRun(
  step: CookRunStep.portion,
  droppedItemIds: const ['i9'],
  pots: CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: true),
  timers: [
    CookTimer(
      id: 't-1',
      label: 'Nudeln',
      endsAt: cookRunStart.add(const Duration(minutes: 9)),
      deviceId: 'dev-1',
    ),
  ],
  meals: const [
    CookMealDraft(
      potId: 'pot-a',
      name: 'Eintopf',
      count: 4,
      inPieces: false,
      grossWeight: 2400,
    ),
    CookMealDraft(
      potId: countedMealPotId,
      name: 'Kekse',
      count: 12,
      inPieces: true,
      grossWeight: null,
    ),
  ],
  lines: [
    cookLine('line-0'),
    cookLine(
      'line-1',
      settlement: LineAssigned(const [
        ItemTake(itemId: 'i1', amount: 200),
        ItemTake(itemId: 'i2', amount: 0),
      ]),
      amount: 300,
      weighed: 295,
      potId: 'pot-a',
      conversion: const CookLineConversion(
        amountPerPiece: 60,
        unit: TemplateIngredientUnit.gram,
      ),
      addedItemIds: const ['i2'],
    ),
    cookLine('line-2', settlement: const LineShopping()),
    cookLine(
      'line-3',
      settlement: const LineIgnored(),
      origin: CookLineOrigin.cooking,
    ),
  ],
);
