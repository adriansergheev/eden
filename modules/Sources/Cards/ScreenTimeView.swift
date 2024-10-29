import ActivityModel
import Dependencies
import SwiftUI
import ManagedSettings
import FamilyControls
import DeviceActivity
import IssueReporting
import StorageClient

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

  struct Store {
    let wrappedStore: ManagedSettingsStore
    let name: ManagedSettingsStore.Name
  }

  @ObservationIgnored
  let store: Store
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
    let dailyPeriod = card.target.screenTime!
    let name = ManagedSettingsStore.Name(rawValue: dailyPeriod.rawValue)
    self.store = .init(wrappedStore: .init(named: name), name: name)
    self.onScreenTimeCompletion = onScreenTimeCompletion
    var startIntervalComponents = DateComponents()
    var endIntervalComponents = DateComponents()

    switch dailyPeriod {
    case .evening:
      startIntervalComponents.hour = 18
      startIntervalComponents.minute = 0
      endIntervalComponents.hour = 22
      endIntervalComponents.minute = 0
    case .morning:
      startIntervalComponents.hour = 6
      startIntervalComponents.minute = 0
      endIntervalComponents.hour = 12
      endIntervalComponents.minute = 0
    }
    let startInterval = Calendar.current.date(from: startIntervalComponents)!
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
        from: try storageClient.load(key: self.store.name.rawValue)
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
//    let event = DeviceActivityEvent(
//      applications: activitySelection.applicationTokens,
//      categories: activitySelection.categoryTokens,
//      webDomains: activitySelection.webDomainTokens,
//      threshold: DateComponents(minute: 1)
//    )

    let center = DeviceActivityCenter()
    center.stopMonitoring()
    try center.startMonitoring(
      .init(self.store.name.rawValue),
      during: schedule
//      events: [.init(self.store.name.rawValue): event]
    )
    try storageClient.save(JSONEncoder().encode(activitySelection), to: self.store.name.rawValue)
  }

  func clear() {
    store.wrappedStore.clearAllSettings()
    try? storageClient.delete(key: self.store.name.rawValue)
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
        body: "Body",
        target: .screenTime(.morning),
        status: .upcoming
      )
    )
  )
}
