import 'package:meta/meta.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';

/// Layout of the Vorrat list.
enum InventoryListViewMode {
  /// One row per entry.
  list,

  /// A grid of small tiles for a quick overview.
  tiles,
}

/// View settings of the Vorrat list that survive a restart.
@immutable
class InventoryListViewPreferences {
  /// Creates the settings.
  const new({
    this.viewMode = InventoryListViewMode.list,
    this.sortMode = InventoryItemSortMode.recentlyAddedDescending,
    this.hideConsumed = true,
    this.groupByReceipt = false,
  });

  /// List or tiles.
  final InventoryListViewMode viewMode;

  /// Order of the entries.
  final InventoryItemSortMode sortMode;

  /// Whether used-up foods and meals are hidden.
  final bool hideConsumed;

  /// Whether foods are grouped by the receipt they came from.
  final bool groupByReceipt;

  /// Copy with.
  InventoryListViewPreferences copyWith({
    InventoryListViewMode? viewMode,
    InventoryItemSortMode? sortMode,
    bool? hideConsumed,
    bool? groupByReceipt,
  }) {
    return InventoryListViewPreferences(
      viewMode: viewMode ?? this.viewMode,
      sortMode: sortMode ?? this.sortMode,
      hideConsumed: hideConsumed ?? this.hideConsumed,
      groupByReceipt: groupByReceipt ?? this.groupByReceipt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryListViewPreferences &&
      other.viewMode == viewMode &&
      other.sortMode == sortMode &&
      other.hideConsumed == hideConsumed &&
      other.groupByReceipt == groupByReceipt;

  @override
  int get hashCode =>
      Object.hash(viewMode, sortMode, hideConsumed, groupByReceipt);
}

/// Reads and writes [InventoryListViewPreferences] in the app preferences.
class InventoryListViewPreferencesStore {
  /// Creates the store.
  const new();

  static const _viewModeKey = 'inventory_list_view_mode';
  static const _sortModeKey = 'inventory_list_sort_mode';
  static const _hideConsumedKey = 'inventory_list_hide_consumed';
  static const _groupByReceiptKey = 'inventory_list_group_by_receipt';

  /// Reads the stored settings; a missing value keeps its default.
  InventoryListViewPreferences read(AppPreferences preferences) {
    const defaults = InventoryListViewPreferences();
    return InventoryListViewPreferences(
      viewMode: _readEnum(
        InventoryListViewMode.values,
        preferences.getStringSync(_viewModeKey),
        defaults.viewMode,
      ),
      sortMode: _readEnum(
        InventoryItemSortMode.values,
        preferences.getStringSync(_sortModeKey),
        defaults.sortMode,
      ),
      hideConsumed: _readBool(
        preferences.getIntSync(_hideConsumedKey),
        defaults.hideConsumed,
      ),
      groupByReceipt: _readBool(
        preferences.getIntSync(_groupByReceiptKey),
        defaults.groupByReceipt,
      ),
    );
  }

  /// Stores [value].
  Future<void> save(
    AppPreferences preferences,
    InventoryListViewPreferences value,
  ) async {
    await preferences.setString(_viewModeKey, value.viewMode.name);
    await preferences.setString(_sortModeKey, value.sortMode.name);
    await preferences.setInt(_hideConsumedKey, value.hideConsumed ? 1 : 0);
    await preferences.setInt(_groupByReceiptKey, value.groupByReceipt ? 1 : 0);
  }

  bool _readBool(int? stored, bool fallback) =>
      stored == null ? fallback : stored != 0;

  T _readEnum<T extends Enum>(List<T> values, String? stored, T fallback) =>
      stored == null ? fallback : values.byName(stored);
}
