import Foundation
import ManagedSettings

public enum DailyPeriod: String, CaseIterable {
  case morning
  case evening
}

extension DailyPeriod {
  var managedSettingsStoreName: ManagedSettingsStore.Name {
    .init("eden-" + self.rawValue)
  }
}
