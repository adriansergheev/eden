import SwiftUI
import FamilyControls
import DeviceActivity

@MainActor
@Observable
final class ClaimModel {
  var activitySelection = FamilyActivitySelection()
  init() {}

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
      intervalStart: DateComponents(hour: 7, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 12, minute: 0, second: 0),
      repeats: true
    )

    let timeLimitMinutes = 30

    let event = DeviceActivityEvent(
      applications: activitySelection.applicationTokens,
      categories: activitySelection.categoryTokens,
      webDomains: activitySelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
    )

    let center = DeviceActivityCenter()
    center.stopMonitoring()

    let activity = DeviceActivityName("Eden.ScreenTime")
    let eventName = DeviceActivityEvent.Name("Eden.Morning")

    do {
      try center.startMonitoring(
        activity,
        during: schedule,
        events: [
          eventName: event
        ]
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
