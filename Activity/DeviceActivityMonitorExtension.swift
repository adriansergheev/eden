import DeviceActivity
import Foundation
import ManagedSettings
import FamilyControls

extension ManagedSettingsStore.Name {
  static let morning = Self("eden.morning")
}

extension URL {
  fileprivate static let morning = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.eden.documents"
  )!.appendingPathComponent("eden-morning.json")
}

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  let morningStore = ManagedSettingsStore(named: .morning)

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    do {
      let applications = try JSONDecoder().decode(
        FamilyActivitySelection.self,
        from: try Data(contentsOf: .morning)
      ).applicationTokens
      morningStore.shield.applications = applications
    } catch {}
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    morningStore.shield.applications = nil
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
