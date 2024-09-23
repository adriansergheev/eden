import Dependencies
import SwiftUI
import ManagedSettings
import FamilyControls
import DeviceActivity
import IssueReporting
import DataManager

extension DeviceActivityName {
  static let daily = DeviceActivityName("eden.daily")
}

extension DeviceActivityEvent.Name {
  static let morning = Self("eden.morning")
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
public final class ScreenTimeModel {
  @ObservationIgnored
  var onScreenTimeCompletion: ((Card) -> Void)

  var isFamilyActivityPickerPresented: Bool = false
  var startTime = Date()
  var endTime = Date()
  var activitySelection = FamilyActivitySelection()
  var card: Card
  var isInProgress: Bool = false

  @ObservationIgnored
  let morningStore = ManagedSettingsStore(named: .morning)
  @ObservationIgnored
  @Dependency(\.dataManager) var dataManager
  @ObservationIgnored
  @Dependency(\.authorizationCenter) var authorizationCenter
  @ObservationIgnored
  @Dependency(\.continuousClock) var clock

  public init(
    card: Card,
    onScreenTimeCompletion: @escaping ((Card) -> Void) = unimplemented("onScreenTimeCompletion")
  ) {
    self.card = card
    self.onScreenTimeCompletion = onScreenTimeCompletion
    var startIntervalComponents = DateComponents()
    startIntervalComponents.hour = 6
    startIntervalComponents.minute = 0
    let startInterval = Calendar.current.date(from: startIntervalComponents)!

    var endIntervalComponents = DateComponents()
    endIntervalComponents.hour = 12
    endIntervalComponents.minute = 0
    let endInterval = Calendar.current.date(from: endIntervalComponents)!

    startTime = startInterval
    endTime = endInterval
  }

  private func authorise() async throws {
    try await authorizationCenter.requestAuthorization()
  }

  func task() async {
    if !card.isSolved {
      do {
        try await authorise()
        if let selection = loadSelection() {
          self.activitySelection = selection
        } else {
          isFamilyActivityPickerPresented = true
        }
        print("✅")
      } catch {
        // TODO: auth could not be obtained
        print("🔴")
      }
    } else {
      clear()
      card.isSolved = false
      isInProgress = true
      try? await clock.sleep(for: .seconds(1))
      isInProgress = false
      onScreenTimeCompletion(card)
      print("Cleared 👍")
    }
  }

  var isResolvedButtonDisabled: Bool {
    activitySelection.applicationTokens.isEmpty
    && activitySelection.categoryTokens.isEmpty
    && activitySelection.webDomainTokens.isEmpty
  }

  var isResolvingOngoing: Bool = false

  private func loadSelection() -> FamilyActivitySelection? {
    do {
      return try JSONDecoder().decode(
        FamilyActivitySelection.self,
        from: try dataManager.load(from: .morning)
      )
    } catch {
      return nil
    }
  }

  private func monitor() throws {
    let calendar = Calendar.current
    // padding has to be added to avoid invalid Device Activity Monitor range < 15 minutes (from now)
    let intervalStart = calendar.dateComponents([.hour, .minute], from: startTime)
    let intervalEnd = calendar.dateComponents([.hour, .minute], from: endTime)

    let schedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true
    )

    // eventDidReachThreshold
    let event = DeviceActivityEvent(
      applications: activitySelection.applicationTokens,
      categories: activitySelection.categoryTokens,
      webDomains: activitySelection.webDomainTokens,
      threshold: DateComponents(second: 1)
    )

    let center = DeviceActivityCenter()
    center.stopMonitoring()
    try center.startMonitoring(
      .daily,
      during: schedule,
      events: [.morning: event]
    )
    try dataManager.save(JSONEncoder().encode(activitySelection), to: .morning)
  }

  func clear() {
    morningStore.shield.applications = nil
  }

  func selectApplicationsTapped() {
    isFamilyActivityPickerPresented = true
  }

  func resolveButtonTapped() async {
    defer { isResolvingOngoing = false }
    isResolvingOngoing = true
    do {
      try monitor()
      print("🍾 monitoring")
      try await clock.sleep(for: .seconds(1))
      card.isSolved = true
      onScreenTimeCompletion(card)
    } catch let error {
      print("🚗 \(error)")
    }
  }
}

struct ScreenTimeView: View {
  @State var model: ScreenTimeModel
  @State var isResolvedProgressViewShown: Bool = false

  init(model: ScreenTimeModel) {
    self.model = model
  }

  var body: some View {
    Group {
      if model.isInProgress {
        ProgressView()
      } else {
        VStack(spacing: 16) {
          Text("Apps you select will not be available during the time period.")
          DatePicker("Start time", selection: $model.startTime, displayedComponents: .hourAndMinute)
          DatePicker("End time", selection: $model.endTime, displayedComponents: .hourAndMinute)
          Button {
            Task {
              await model.resolveButtonTapped()
            }
          } label: {
            HStack {
              Text("Resolve")
              if model.isResolvingOngoing {
                ProgressView()
              }
            }
          }
          .disabled(model.isResolvedButtonDisabled)

          Spacer()
          //      Button {
          //        model.clear()
          //      } label: {
          //        Text("DEBUG Clear")
          //          .tint(.red)
          //      }
        }
        .padding()
        .familyActivityPicker(
          isPresented: self.$model.isFamilyActivityPickerPresented,
          selection: $model.activitySelection
        )
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Select") {
              model.selectApplicationsTapped()
            }
            .tint(.green)
          }
        }
      }
    }
    .task {
      await model.task()
    }
  }
}

#Preview {
  ScreenTimeView(
    model: .init(
      card: .init(
        id: .init(),
        title: "Title",
        description: "Description"
      )
    )
  )
}
