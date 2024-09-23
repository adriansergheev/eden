import SwiftUI
import IssueReporting
import SwiftUINavigation
import Dependencies
import StorageClient
import IdentifiedCollections

extension String {
  fileprivate static let cardsStatusKey = "cardsStatus"
}

@MainActor
@Observable
public class CardsModel {
  enum Destination: Identifiable {
    case detail(Card)
    case action(Card)

    var id: UUID {
      switch self {
      case let .detail(card):
        return card.id
      case let .action(card):
        return card.id
      }
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
  var saveTask: Task<Void, Error>?

  @ObservationIgnored
  @Dependency(\.storageClient) var storageClient
  @ObservationIgnored
  @Dependency(\.continuousClock) var clock
  @ObservationIgnored
  @Dependency(\.uuid) var uuid

  public init() {
    self.cards = .init(uniqueElements: [
      .init(id: uuid(), title: "Claim your mornings", description: "Think about the amount of time spent every morning on things which don't matter.", status: .solved(false)),
      .init(id: uuid(), title: "Take control of Youtube", description: "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua", status: .solved(true)),
      .init(id: uuid(), title: "Instagram", description: "Coming soon...", status: .upcoming)
    ])
    do {
      // previous cards status is present
      let cardsStatus = try JSONDecoder().decode(
        [UUID: Bool?].self,
        from: try storageClient.load(from: .cardsStatusKey)
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
    saveTask?.cancel()
    saveTask = nil
    saveTask = Task {
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

  func actionButtonTapped(_ card: Card) {
    destination = .action(card)
  }

  func dismissCardButtonTapped() {
    destination = nil
  }

  func onScreenTimeCompleted(card: Card) {
    withAnimation {
      cards[id: card.id] = card
    }
    save()
    destination = nil
  }
}

@MainActor
public struct CardsView: View {
  @State var model: CardsModel

  public init(model: CardsModel) {
    self.model = model
  }

  public var body: some View {
    NavigationView {
      VStack {
        HStack {
          Text("Working for you")
            .font(.callout)
          Spacer()
        }
        .padding(.horizontal)
        ScrollView {
          makeSection(nil, cards: model.unSolvedCards)
          makeSection("Resolved", cards: model.cards.filter(\.isSolved))
          makeSection("Upcoming", cards: model.upcomingCards)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
      }
      .navigationTitle("Your iPhone")
      .background(Color(UIColor.systemGroupedBackground))
    }
    .sheet(item: $model.destination) { destination in
      NavigationStack {
        makeDestination(destination)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Dismiss") {
                self.model.dismissCardButtonTapped()
              }
            }
          }
      }
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

  @ViewBuilder
  func makeDestination(_ destination: CardsModel.Destination) -> some View {
    switch destination {
    case .detail:
      ScreenTimeCardDetailView()
    case let .action(card):
      ScreenTimeView(
        model: .init(
          card: card, onScreenTimeCompletion: { card in
            model.onScreenTimeCompleted(card: card)
          }
        )
      )
      .presentationDetents([.medium])
      .presentationDragIndicator(.hidden)
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
        .disabled(card.status.solved == nil || card.status.solved == false)
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
      .frame(maxWidth: .infinity)
    }
    .padding()
    .background(colorScheme == .light ? Color.white : nil)
    .clipShape(RoundedRectangle(cornerRadius: 15))
    .shadow(radius: 5)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
  }
}

#Preview {
  CardsView(model: .init())
}
