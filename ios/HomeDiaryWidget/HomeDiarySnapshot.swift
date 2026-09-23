import Foundation

/// App Group the Runner app and this extension share. Must match
/// `homeWidgetIOSAppGroupId` in
/// `lib/features/home_widget/data/home_widget_plugin_bridge.dart` and both
/// targets' entitlements.
let homeWidgetAppGroupId = "group.de.yamt.app"

/// Key `home_widget`'s Flutter side saves the snapshot JSON under. Must match
/// `homeWidgetSnapshotDataKey` in
/// `lib/features/home_widget/data/home_widget_plugin_bridge.dart`.
private let snapshotKey = "diary_home_widget_snapshot"

/// Snapshot Flutter writes for the widget. Field names match
/// `HomeWidgetSnapshot.toJson` in
/// `lib/features/home_widget/application/home_widget_snapshot.dart`.
struct HomeDiarySnapshot: Decodable {
  /// Eaten and target grams of one macro.
  struct Macro {
    let eaten: Double
    let target: Double
  }

  let verbose: Bool
  let eatenKcal: Double
  let targetKcal: Double
  let protein: Macro
  let carbs: Macro
  let fat: Macro

  private enum CodingKeys: String, CodingKey {
    case verbose
    case eatenKcal = "eaten_kcal"
    case targetKcal = "target_kcal"
    case proteinGrams = "protein_grams"
    case proteinGoalGrams = "protein_goal_grams"
    case carbsGrams = "carbs_grams"
    case carbsGoalGrams = "carbs_goal_grams"
    case fatGrams = "fat_grams"
    case fatGoalGrams = "fat_goal_grams"
  }

  init(
    verbose: Bool, eatenKcal: Double, targetKcal: Double, protein: Macro, carbs: Macro, fat: Macro
  ) {
    self.verbose = verbose
    self.eatenKcal = eatenKcal
    self.targetKcal = targetKcal
    self.protein = protein
    self.carbs = carbs
    self.fat = fat
  }

  init(from decoder: Decoder) throws {
    let json = try decoder.container(keyedBy: CodingKeys.self)
    verbose = try json.decode(Bool.self, forKey: .verbose)
    eatenKcal = try json.decode(Double.self, forKey: .eatenKcal)
    targetKcal = try json.decode(Double.self, forKey: .targetKcal)
    protein = Macro(
      eaten: try json.decode(Double.self, forKey: .proteinGrams),
      target: try json.decode(Double.self, forKey: .proteinGoalGrams))
    carbs = Macro(
      eaten: try json.decode(Double.self, forKey: .carbsGrams),
      target: try json.decode(Double.self, forKey: .carbsGoalGrams))
    fat = Macro(
      eaten: try json.decode(Double.self, forKey: .fatGrams),
      target: try json.decode(Double.self, forKey: .fatGoalGrams))
  }

  /// Last snapshot the app saved, or `nil` before the first sync.
  static func load() -> HomeDiarySnapshot? {
    guard
      let json = UserDefaults(suiteName: homeWidgetAppGroupId)?.string(forKey: snapshotKey),
      let data = json.data(using: .utf8)
    else {
      return nil
    }
    return try? JSONDecoder().decode(HomeDiarySnapshot.self, from: data)
  }

  /// Sample values the widget gallery shows before the first sync.
  static let preview = HomeDiarySnapshot(
    verbose: false,
    eatenKcal: 1240,
    targetKcal: 2100,
    protein: Macro(eaten: 82, target: 140),
    carbs: Macro(eaten: 130, target: 220),
    fat: Macro(eaten: 41, target: 70))
}
