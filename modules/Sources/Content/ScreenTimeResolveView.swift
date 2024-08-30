import Dependencies
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

extension URL {
  fileprivate static let morning = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.eden.documents"
  )!.appendingPathComponent("eden-morning.json")
}

@MainActor
@Observable
public final class ClaimModel {
  @ObservationIgnored
  let morningStore = ManagedSettingsStore(named: .morning)
  @ObservationIgnored
  var activitySelection = FamilyActivitySelection() 
//  {
//    didSet {
//      morningStore.shield.applications = activitySelection.applicationTokens
//    }
//  }
  @ObservationIgnored
  @Dependency(\.dataManager) var dataManager
  @ObservationIgnored
  @Dependency(\.authorizationCenter) var authorizationCenter

  public init() {}

  func authorise() async {
    do {
      try await authorizationCenter.requestAuthorization()
      print("✅")
    } catch {
      print("🔴")
    }
  }

  func monitor() {
    //    let startDate = Date(timeIntervalSinceNow: 1.0) // padding added to avoid invalid DAM ranges < 15 mins.
    //    let endDate = DateComponents(hour: 23, minute: 59)
    //    let components: Set<Calendar.Component> = [.day, .month, .year, .hour, .minute, .second]
    //    let calendar = Calendar.current
    //    let intervalStart = calendar.dateComponents(components, from: startDate)
    //
    //    let schedule = DeviceActivitySchedule(
    //      intervalStart: intervalStart,
    //      intervalEnd: endDate,
    //      repeats: false
    //    )
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 8, minute: 0),
      intervalEnd: DateComponents(hour: 12, minute: 59),
      repeats: true
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
      try dataManager.save(JSONEncoder().encode(activitySelection), to: .morning)
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

#Preview {
  ScreenTimeResolveView(model: .init())
}
