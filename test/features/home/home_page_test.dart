import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_quick_add_dialog.dart';
import '../calories/support/fake_calories_repositories.dart';
import '../shoppinglist/support/fake_shopping_list_repository.dart';

class _MockUser extends Mock implements User {}

_MockUser _authenticatedUser() {
  final user = _MockUser();
  when(() => user.uid).thenReturn('uid-123');
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.displayName).thenReturn('Jane Doe');
  when(() => user.email).thenReturn('jane@example.com');
  return user;
}

class _FakeAppPreferences implements AppPreferences {
  _FakeAppPreferences({Map<String, Object>? initialValues})
    : _values = initialValues ?? <String, Object>{};

  final Map<String, Object> _values;

  @override
  String? getStringSync(String key) {
    return _values[key] as String?;
  }

  @override
  int? getIntSync(String key) {
    return _values[key] as int?;
  }

  @override
  Future<String?> getString(String key) async {
    return _values[key] as String?;
  }

  @override
  Future<int?> getInt(String key) async {
    return _values[key] as int?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }
}

ProviderContainer _createContainer() {
  final shoppingRepository = FakeShoppingListRepository();
  final calorieLogRepository = FakeCalorieLogRepository();
  final calorieSettingsRepository = FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream<User?>.value(_authenticatedUser()),
      ),
      appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
      shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
      calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(shoppingRepository.dispose);
  addTearDown(calorieLogRepository.dispose);
  addTearDown(calorieSettingsRepository.dispose);
  return container;
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('home shell shows app bar and tabs for authenticated user', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    expect(find.text('Inventory'), findsAtLeastNWidgets(1));
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('inventory FAB opens receipt action sheet', (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);

    expect(find.text('Scan receipt (camera)'), findsOneWidget);
    expect(find.text('Upload receipt (image/PDF)'), findsOneWidget);
  });

  testWidgets('shopping FAB opens add dialog and adds item', (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(ShoppingQuickAddDialogKeys.nameField), findsOneWidget);

    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.nameField),
      'Milk',
    );
    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.brandField),
      'Acme',
    );
    await tester.tap(find.byKey(ShoppingQuickAddDialogKeys.confirmButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('shopping FAB shows validation error on empty name', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.nameField),
      ' ',
    );
    await tester.tap(find.byKey(ShoppingQuickAddDialogKeys.confirmButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Please enter an item name.'), findsOneWidget);
  });

  testWidgets('shopping quick-add cancel closes dialog and keeps list', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpUi(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    await tester.enterText(
      find.byKey(ShoppingQuickAddDialogKeys.nameField),
      'Milk',
    );
    await tester.tap(find.byKey(ShoppingQuickAddDialogKeys.cancelButton));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Milk'), findsNothing);
  });

  testWidgets('calories FAB opens add-options sheet and manual entry route', (
    tester,
  ) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await _pumpUi(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);

    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);

    await tester.tap(find.byKey(CaloriesPageKeys.addOptionsManualButton));
    await _pumpUi(tester);
    expect(find.text('Add calorie entry'), findsOneWidget);
    expect(find.byKey(CalorieEntryEditorKeys.nameField), findsOneWidget);
  });

  testWidgets('settings FAB shows context snackbar', (tester) async {
    final container = _createContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Settings').first);
    await _pumpUi(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await _pumpUi(tester);
    expect(find.text('Settings action coming soon.'), findsOneWidget);
  });
}
