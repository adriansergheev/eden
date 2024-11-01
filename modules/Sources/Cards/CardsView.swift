import SwiftUI
import IssueReporting
import SwiftUINavigation
import Dependencies
import Settings
import StorageClient
import IdentifiedCollections

extension String {
  fileprivate static let cardsStatusKey = "cardsStatus"
}

@MainActor
@Observable
public class CardsModel {
  @CasePathable
  @dynamicMemberLookup
  enum Destination {
    case detail(Card)
    case action(Card)
    case alert(AlertState<AlertAction>)
    case settings(SettingsModel)

    enum AlertAction {
      case confirm(Card)
    }
  }

  var destination: Destination?
  var cards = IdentifiedArrayOf<Card>()

  var unSolvedCards: IdentifiedArrayOf<Card> {
    cards.filter {
      switch $0.status {
      case let .solved(isSolved):
        return !isSolved
      case .upcoming:
        return false
      }
    }
  }

  var upcomingCards: IdentifiedArrayOf<Card> {
    cards.filter {
      switch $0.status {
      case .solved:
        return false
      case .upcoming:
        return true
      }
    }
  }

  @ObservationIgnored
  var saveDebouncedTask: Task<Void, Error>?

  @ObservationIgnored
  @Dependency(\.storageClient) var storageClient
  @ObservationIgnored
  @Dependency(\.continuousClock) var clock
  @ObservationIgnored
  @Dependency(\.uuid) var uuid

  public init() {
    self.cards = .init(
      uniqueElements: [
        .init(
          id: uuid(),
          title: "Claim your mornings",
          description: "Start your day.",
          body: """
Mornings can easily slip away with distractions. Taking control of your mornings sets the tone for a more productive and focused day.

Owning your mornings means intentionally limiting distractions and dedicating time to what is most important for you.
""",
          target: .screenTime(.morning),
          status: .solved(false)
        ),
        .init(
          id: uuid(),
          title: "Claim your evenings",
          description: "You deserve to unwind.",
          body: """
Evenings are often stolen by endless scrolling and notifications. Taking control of this time can improve your overall well-being.

Reclaiming your evenings means consciously limiting distractions and dedicating time to unwind and do what truly matters to you.
""",
          target: .screenTime(.evening),
          status: .solved(false)
        ),
        .init(
          id: uuid(),
          title: "Take control of Youtube",
          description: "Reflect on how much of your time is lost.",
          body: """
YouTube’s algorithms are designed to keep you watching, but you can make choices that help you stay in control rather than scrolling endlessly.

Taking control of YouTube means setting boundaries so you can enjoy content that matters without letting endless recommendations take over your valuable time.
""",
          target: .tutorial,
          status: .solved(false)
        ),
        .init(
          id: uuid(),
          title: "Instagram",
          description: "Coming soon...",
          body: "upcoming body",
          target: .tutorial,
          status: .upcoming
        )
      ]
    )
    do {
      // previous cards status is present
      let cardsStatus = try JSONDecoder().decode(
        [UUID: Bool?].self,
        from: try storageClient.load(key: .cardsStatusKey)
      )
      for card in cardsStatus {
        if let isSolved = card.value {
          cards[id: card.key]?.status = .solved(isSolved)
        }
      }
    } catch {
      // no previous cards data
    }
  }

  private func save() {
    saveDebouncedTask?.cancel()
    saveDebouncedTask = Task {
      try await clock.sleep(for: .milliseconds(300))
      let cardsStatus: [UUID: Bool?] = Dictionary(
        uniqueKeysWithValues: cards.map { card in
          if case let .solved(isSolved) = card.status {
            return (card.id, isSolved)
          }
          return (card.id, nil)
        }
      )
      try self.storageClient.save(try JSONEncoder().encode(cardsStatus), to: .cardsStatusKey)
    }
  }

  func whyShouldYouCareButtonTapped(_ card: Card) {
    destination = .detail(card)
  }

  var hasSeenTutorialDisclaimer: Bool = false

  func alertButtonTapped(_ action: Destination.AlertAction?) {
    switch action {
    case let .confirm(card):
      destination = .action(card)
    case .none: break
    }
  }

  func actionButtonTapped(_ card: Card) {
    switch card.target {
    case .tutorial:
      if !(hasSeenTutorialDisclaimer || card.isSolved) {
        defer { hasSeenTutorialDisclaimer = true }
        destination = .alert(.disclaimer(card))
        return
      }
      if card.isSolved {
        var card = card
        card.status = .solved(false)
        update(card)
        return
      }
      destination = .action(card)
    case .screenTime:
      destination = .action(card)
    }
  }

  func dismissCardButtonTapped() {
    destination = nil
  }

  private func update(_ card: Card) {
    withAnimation {
      cards[id: card.id] = card
    }
    save()
  }

  func onResolved(card: Card) {
    update(card)
    destination = nil
  }

  func onOpenSettingsButtonTapped() {
    destination = .settings(.init())
  }

  func onDismissSettingsButtonTapped() {
    destination = nil
  }
}

extension AlertState where Action == CardsModel.Destination.AlertAction {
  static func disclaimer(_ card: Card) -> Self {
    .init {
      TextState("Action Required")
    } actions: {
      ButtonState(role: .cancel, action: .confirm(card)) {
        TextState("Confirm")
      }
    } message: {
      TextState("Some actions need to be done manually. \nFollow the provided tutorial to adjust settings on your device.")
    }
  }
}

@MainActor
public struct CardsView: View {
  @State var model: CardsModel

  public init(model: CardsModel) {
    self.model = model
  }

  public var body: some View {
    ScrollView {
      VStack {
        HStack {
          Text("Working for you")
            .font(.callout)
          Spacer()
        }
        .padding(.horizontal)
        makeSection(nil, cards: model.unSolvedCards)
        makeSection("Resolved", cards: model.cards.filter(\.isSolved))
        makeSection("Upcoming", cards: model.upcomingCards)
      }
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .toolbar {
      Button {
        model.onOpenSettingsButtonTapped()
      } label: {
        Image(systemName: "gear.circle.fill")
          .tint(.green)
      }
    }
    .navigationTitle("Your iPhone")
    .sheet(item: $model.destination.detail) { card in
      NavigationStack {
        CardDetailView(card: card)
          .cardToolBar {
            self.model.dismissCardButtonTapped()
          }
      }
    }
    .sheet(item: $model.destination.action) { card in
      NavigationStack {
        Group {
          switch card.target {
          case .screenTime:
            ScreenTimeView(
              model: .init(
                card: card, onScreenTimeCompletion: { card in
                  model.onResolved(card: card)
                }
              )
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
          case .tutorial:
            TutorialView(
              model: .init(
                card: card, onTutorialCompleted: { card in
                  model.onResolved(card: card)
                }
              )
            )
          }
        }
        .cardToolBar {
          self.model.dismissCardButtonTapped()
        }
      }
    }
    .sheet(item: $model.destination.settings) { model in
      NavigationStack {
        SettingsView(model: model)
          .navigationTitle("Settings")
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                self.model.onDismissSettingsButtonTapped()
              }
            }
          }
      }
    }
    .alert($model.destination.alert) { action in
      model.alertButtonTapped(action)
    }
  }

  @ViewBuilder
  func makeSection(_ title: String?, cards: IdentifiedArrayOf<Card>) -> some View {
    if let title {
      Section {
        ForEach(cards) { card in
          CardView(
            card: card,
            primaryAction: { model.actionButtonTapped(card) }
          )
        }
      } header: {
        if !cards.isEmpty {
          HStack {
            VStack {
              Divider()
            }
            Text(title)
              .fontWeight(.thin)
              .font(.subheadline)
            VStack {
              Divider()
            }
          }
          .transaction { $0.animation = nil }
        }
      }

    } else {
      Section {
        ForEach(cards) { card in
          CardView(
            card: card,
            primaryAction: { model.actionButtonTapped(card) },
            secondaryAction: { model.whyShouldYouCareButtonTapped(card) }
          )
        }
      }
    }
  }
}

extension View {
  func cardToolBar(_ action: @escaping (() -> Void)) -> some View {
    modifier(ToolBarModifier(action: action))
  }
}


struct ToolBarModifier: ViewModifier {
  let action: (() -> Void)
  func body(content: Content) -> some View {
    content
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Dismiss") {
            action()
          }
        }
      }
  }
}

struct CardView: View {
  @Environment(\.colorScheme) var colorScheme
  let card: Card

  var primaryAction: (() -> Void) = unimplemented("primaryAction")
  var secondaryAction: (() -> Void) = unimplemented("secondaryAction")

  func accentColor(for card: Card) -> Color {
    switch card.status {
    case let .solved(isSolved):
      return isSolved ? .gray : .green
    case .upcoming:
      return .gray
    }
  }

  func primaryActionBackgroundColor(for card: Card) -> Color {
    switch card.status {
    case let .solved(isSolved):
      if isSolved {
        return colorScheme == .light ? .white : .clear
      } else {
        return .green.opacity(0.8)
      }
    case .upcoming:
      return .gray.opacity(0.5)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(card.title)
          .font(.headline)
          .foregroundColor(.primary)
        Spacer()
      }
      .padding(.bottom, 2)

      Text(card.description)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.bottom, 8)

      HStack {
        Button(action: {
          secondaryAction()
        }) {
          HStack {
            Image(systemName: "play.circle.fill")
              .foregroundColor(accentColor(for: card))
            Text("Why you should care")
              .font(.subheadline)
              .foregroundColor(accentColor(for: card))
          }
          .padding(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(accentColor(for: card), lineWidth: 1)
          )
        }
        .disabled(!(card.status.solved == false))
        Spacer()
        Button(action: {
          primaryAction()
        }) {
          Text(!card.isSolved ? "Resolve" : "Clear")
            .font(.subheadline)
            .foregroundColor(card.isSolved ? .red.opacity(0.8) : .white)
            .padding(8)
            .frame(minWidth: 80)
            .background(primaryActionBackgroundColor(for: card))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(card.isSolved ? Color.red.opacity(0.8) : .clear, lineWidth: 1)
            )
        }
      }
      .disabled(card.status.upcoming != nil)
      .frame(maxWidth: .infinity)
    }
    .padding()
    .background(colorScheme == .light ? Color.white : Color.gray.opacity(0.2))
    .clipShape(RoundedRectangle(cornerRadius: 15))
    .shadow(radius: 5)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
  }
}

#Preview {
  CardsView(model: .init())
}
