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

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    do {
      let applications = try JSONDecoder().decode(
        FamilyActivitySelection.self,
        from: try Data(contentsOf: URL.base.appendingPathComponent(.eveningKey).appendingPathExtension("json"))
      ).applicationTokens
      store.shield.applications = applications
    } catch {}
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    store.shield.applications = nil
  }

  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)
    // Handle the event reaching its threshold.
  }

  override func intervalWillStartWarning(for activity: DeviceActivityName) {
    super.intervalWillStartWarning(for: activity)
    // Handle the warning before the interval starts.
  }

  override func intervalWillEndWarning(for activity: DeviceActivityName) {
    super.intervalWillEndWarning(for: activity)

    // Handle the warning before the interval ends.
  }

  override func eventWillReachThresholdWarning(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    // Handle the warning before the event reaches its threshold.
  }
}
