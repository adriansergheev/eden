import Dependencies
import SwiftUI
import ManagedSettings
import FamilyControls
import DeviceActivity
import IssueReporting
import StorageClient

extension DeviceActivityName {
  static let daily = DeviceActivityName("eden.daily")
}

extension DeviceActivityEvent.Name {
  static let eveningKey = Self(String.eveningKey)
}

extension ManagedSettingsStore.Name {
  static let evening = Self(String.eveningKey)
}

extension String {
  fileprivate static let eveningKey = "eden-evening"
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
  let store = ManagedSettingsStore(named: .evening)
  @ObservationIgnored
  @Dependency(\.storageClient) var storageClient
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
    startIntervalComponents.hour = 18
    startIntervalComponents.minute = 0
    let startInterval = Calendar.current.date(from: startIntervalComponents)!

    var endIntervalComponents = DateComponents()
    endIntervalComponents.hour = 22
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
      card.status = .solved(false)
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
        from: try storageClient.load(key: .eveningKey)
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
      events: [.eveningKey: event]
    )
    try storageClient.save(JSONEncoder().encode(activitySelection), to: .eveningKey)
  }

  func clear() {
    store.clearAllSettings()
    store.shield.applications = nil
    try? storageClient.delete(key: .eveningKey)
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
      card.status = .solved(true)
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
            VStack {
              if model.isResolvingOngoing {
                ProgressView()
              }
              Text("Resolve")
                .foregroundColor(model.isResolvedButtonDisabled ? Color.green.opacity(0.5) : Color.green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(model.isResolvedButtonDisabled ? Color.gray.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(12)
            }
          }
          .disabled(model.isResolvedButtonDisabled)
          Spacer()
        }
        .padding()
        .familyActivityPicker(
          isPresented: self.$model.isFamilyActivityPickerPresented,
          selection: $model.activitySelection
        )
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Choose Activities") {
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
        description: "Description",
        target: .screenTime,
        status: .upcoming
      )
    )
  )
}
