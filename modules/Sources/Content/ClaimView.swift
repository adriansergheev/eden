import SwiftUI
//import ManagedSettings // shield with custom ui
import FamilyControls
import DeviceActivity

extension DeviceActivityName {
  static let daily = DeviceActivityName("eden.daily")
}

extension DeviceActivityEvent.Name {
  static let tbd = Self("eden.tbd")
}

@MainActor
@Observable
final class ClaimModel {
  public var activitySelection = FamilyActivitySelection()
  public init() {}

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
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59),
      repeats: true
    )

    let timeLimitMinutes = 30

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
}

struct ClaimView: View {
  @State var isPickerPresented = false
  @State var model: ClaimModel

  @State var isDemoModalPresented: Bool = false

  init(model: ClaimModel) {
    self.model = model
  }

  var body: some View {
    VStack {
      Text("Claim View")
      Button {
        isPickerPresented = true
      } label: {
        Text("Select Appplications")
      }
      Button {
        model.monitor()
      } label: {
        Text("Monitor")
      }
      Button {
        isDemoModalPresented = true
      } label: {
        Text("DeviceActivityView")
      }
    }
    .task {
      await model.authorise()
    }
    .familyActivityPicker(
      isPresented: self.$isPickerPresented,
      selection: $model.activitySelection
    )
    .sheet(isPresented: $isDemoModalPresented) {
      DeviceActivityView()
    }
  }
}
