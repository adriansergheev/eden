import DeviceActivity
import ManagedSettings
import Content

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  let store = ManagedSettingsStore()

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    // TOOD: set restrictions
    // apparently, you can hit the app's model here
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

  override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventWillReachThresholdWarning(event, activity: activity)

    // Handle the warning before the event reaches its threshold.
  }
}
