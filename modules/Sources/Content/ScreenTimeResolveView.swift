import SwiftUI
import ManagedSettings
import FamilyControls
import DeviceActivity

extension DeviceActivityName {
  static let daily = DeviceActivityName("eden.daily")
}

extension DeviceActivityEvent.Name {
  static let tbd = Self("eden.tbd")
}

extension ManagedSettingsStore.Name {
  static let morning = Self("eden.morning")
}

@MainActor
@Observable
public final class ClaimModel {
  @ObservationIgnored
  let morningStore = ManagedSettingsStore(named: .morning)
  @ObservationIgnored
  var activitySelection = FamilyActivitySelection() {
    didSet {
      morningStore.shield.applications = activitySelection.applicationTokens
    }
  }

  public init() {}

  // TODO: move this at the start of the app. Activity report can't show it's thing if this is not hit first.
  func authorise() async {
    let authorizationCenter = AuthorizationCenter.shared
    do {
      try await authorizationCenter.requestAuthorization(
        for: .individual
      )
      print("✅")
    } catch {
      print("🔴")
    }
  }

  func monitor() {
    let startDate = Date(timeIntervalSinceNow: 1.0) // padding added to avoid invalid DAM ranges < 15 mins.
    let endDate = DateComponents(hour: 23, minute: 59)
//    let schedule = DeviceActivitySchedule(
//      intervalStart: DateComponents(hour: 0, minute: 0),
//      intervalEnd: DateComponents(hour: 23, minute: 59),
//      repeats: true
//    )

    let components: Set<Calendar.Component> = [.day, .month, .year, .hour, .minute, .second]
    let calendar = Calendar.current
    let intervalStart = calendar.dateComponents(components, from: startDate)

    let schedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: endDate,
      repeats: false
    )

    let timeLimitMinutes = 1

    // this hits eventDidReachThreshold
    let event = DeviceActivityEvent(
      applications: activitySelection.applicationTokens,
      categories: activitySelection.categoryTokens,
      webDomains: activitySelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
    )

    let center = DeviceActivityCenter()
    center.stopMonitoring()

    do {
      try center.startMonitoring(
        .daily,
        during: schedule,
        events: [.tbd: event]
      )
      print("🍾 monitoring")
    } catch let error {
      print("🚗 \(error)")
    }
  }

  func clear() {
    morningStore.shield.applications = nil
  }
}

struct ScreenTimeResolveView: View {
  @State var isPickerPresented = false
  @State var model: ClaimModel

  init(model: ClaimModel) {
    self.model = model
  }

  var body: some View {
    VStack(spacing: 16) {
      Button {
        isPickerPresented = true
      } label: {
        Text("Select Applications")
      }
      Button {
        model.monitor()
      } label: {
        Text("Monitor Morning")
      }
      Button {
        model.clear()
      } label: {
        Text("Clear")
      }
    }
    .task {
      await model.authorise()
    }
    .familyActivityPicker(
      isPresented: self.$isPickerPresented,
      selection: $model.activitySelection
    )
  }
}
