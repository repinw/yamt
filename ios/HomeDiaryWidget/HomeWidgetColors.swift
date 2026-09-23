import SwiftUI
import UIKit

/// Same light/dark values as the Android widget's
/// `android/app/src/main/res/values{,-night}/colors.xml`: Material 3 baseline
/// tokens and the MetricAccentColors macro accents the Diary card uses.
enum HomeWidgetColors {
  static let surface = dynamic(light: 0xFEF7FF, dark: 0x141218)
  static let surfaceContainerLow = dynamic(light: 0xF7F2FA, dark: 0x1D1B20)
  static let outlineVariant = dynamic(light: 0xCAC4D0, dark: 0x49454F)
  static let onSurface = dynamic(light: 0x1D1B20, dark: 0xE6E0E9)
  static let onSurfaceVariant = dynamic(light: 0x49454F, dark: 0xCAC4D0)
  static let primary = dynamic(light: 0x6750A4, dark: 0xD0BCFF)
  static let error = dynamic(light: 0xB3261E, dark: 0xF2B8B5)
  static let protein = dynamic(light: 0xDD2251, dark: 0xE96888)
  static let carbs = dynamic(light: 0x1B57E4, dark: 0x608BF1)
  static let fat = dynamic(light: 0xE99716, dark: 0xF6BE65)

  private static func dynamic(light: UInt32, dark: UInt32) -> Color {
    Color(
      UIColor { traits in
        rgb(traits.userInterfaceStyle == .dark ? dark : light)
      })
  }

  private static func rgb(_ hex: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1)
  }
}
