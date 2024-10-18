import ActivityModel
import DeviceActivity
import Foundation
import ManagedSettings
import FamilyControls

extension URL {
  fileprivate static let base = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.eden.documents"
  )!
}

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  var stores = [String: ManagedSettingsStore]()

  public override init() {
    super.init()
    for period in DailyPeriod.allCases {
      stores[period.rawValue] = .init(named: .init(period.rawValue))
    }
  }

  func getActivities(for key: String) -> FamilyActivitySelection? {
    do {
      return try JSONDecoder().decode(
        FamilyActivitySelection.self,
        from: try Data(contentsOf: URL.base.appendingPathComponent(key).appendingPathExtension("json"))
      )
    } catch {}
    return nil
  }

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    stores[activity.rawValue]?.clearAllSettings()

    if let activities = getActivities(for: activity.rawValue) {
      stores[activity.rawValue]?.shield.applications = activities.applicationTokens
      stores[activity.rawValue]?.shield.applicationCategories = .specific(activities.categoryTokens, except: .init())
    }
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    stores[activity.rawValue]?.clearAllSettings()
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
