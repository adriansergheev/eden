import DeviceActivity
import Foundation
import ManagedSettings
import FamilyControls

extension String {
  fileprivate static let eveningKey = "eden-evening"
}

extension ManagedSettingsStore.Name {
  static let store = Self(.eveningKey)
}

extension URL {
  fileprivate static let base = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.eden.documents"
  )!
}

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  let store = ManagedSettingsStore(named: .store)

  func getActivities() -> FamilyActivitySelection? {
    do {
      return try JSONDecoder().decode(
        FamilyActivitySelection.self,
        from: try Data(contentsOf: URL.base.appendingPathComponent(.eveningKey).appendingPathExtension("json"))
      )
    } catch {}
    return nil
  }

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    store.clearAllSettings()
    if let activities = getActivities() {
      store.shield.applications = activities.applicationTokens
      store.shield.applicationCategories = .specific(activities.categoryTokens, except: .init())
    }
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    store.clearAllSettings()
  }

  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)
  }

  override func intervalWillStartWarning(for activity: DeviceActivityName) {
    super.intervalWillStartWarning(for: activity)
  }

  override func intervalWillEndWarning(for activity: DeviceActivityName) {
    super.intervalWillEndWarning(for: activity)
  }

  override func eventWillReachThresholdWarning(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventWillReachThresholdWarning(event, activity: activity)
  }
}
