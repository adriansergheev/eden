import SwiftUI
import IssueReporting
import SwiftUINavigation
import Dependencies
import StorageClient
import IdentifiedCollections

extension URL {
  fileprivate static let cardsStatus = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.eden.documents"
  )!.appendingPathComponent("cardsStatus").appendingPathExtension("json")
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
      .init(id: uuid(), title: "Claim your mornings", description: "Think about the amount of time spent every morning on things which don't matter."),
      .init(id: uuid(), title: "Take control of Youtube", description: "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua", isSolved: true),
      .init(id: uuid(), title: "Instagram", description: "Coming soon...", isSolved: true)
    ])
    do {
      // previous cards status is present
      let cardsStatus = try JSONDecoder().decode(
        [UUID: Bool].self,
        from: try storageClient.load(from: .cardsStatus)
      )
      for card in cardsStatus {
        cards[id: card.key]?.isSolved = card.value
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
      let cardsStatus: [UUID: Bool] = Dictionary(
        uniqueKeysWithValues: cards.map { ($0.id, $0.isSolved)}
      )
      try self.storageClient.save(try JSONEncoder().encode(cardsStatus), to: .cardsStatus)
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
          VStack {
            Section {
              ForEach(model.cards.filter { !$0.isSolved }) { card in
                CardView(
                  card: card,
                  primaryAction: { model.actionButtonTapped(card) },
                  secondaryAction: { model.whyShouldYouCareButtonTapped(card) }
                )
              }
            }
            Section {
              ForEach(model.cards.filter { $0.isSolved }) { card in
                CardView(
                  card: card,
                  primaryAction: { model.actionButtonTapped(card) }
                )
              }
            } header: {
              HStack {
                VStack {
                  Divider()
                }
                Text("Resolved")
                  .fontWeight(.thin)
                  .font(.subheadline)
                VStack {
                  Divider()
                }
              }
              .transaction { $0.animation = nil }
            }
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 8)
        }
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

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(card.title)
          .font(.headline)
          .foregroundColor(.primary)
        Spacer()
        //        Button(action: {
        //          // Close action
        //        }) {
        //          Image(systemName: "xmark")
        //            .foregroundColor(.gray)
        //        }
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
              .foregroundColor(card.isSolved ? .gray : .green)
            Text("Why you should care")
              .font(.subheadline)
              .foregroundColor(card.isSolved ? .gray : .green)
          }
          .padding(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(card.isSolved ? .gray : .green, lineWidth: 1)
          )
        }
        .disabled(card.isSolved)
        Spacer()
        Button(action: {
          primaryAction()
        }) {
          Text(!card.isSolved ? "Resolve" : "Clear")
            .font(.subheadline)
            .foregroundColor(card.isSolved ? .red.opacity(0.8) : .white)
            .padding(8)
            .frame(minWidth: 80)
          // TODO: do something about white in dark mode
            .background(card.isSolved ? .white : .green)
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
