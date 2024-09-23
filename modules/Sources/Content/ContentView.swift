import SwiftUI
import IssueReporting
import SwiftUINavigation
import IdentifiedCollections

@MainActor
public let cards: IdentifiedArrayOf<Card> = [
  .init(id: UUID(), title: "Claim your mornings", description: "Think about the amount of time spent every morning on things which don't matter."),
  .init(id: UUID(), title: "Take control of Youtube", description: "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua", isSolved: true),
  .init(id: UUID(), title: "Instagram", description: "Coming soon...", isSolved: true)
]

@MainActor
@Observable
public class ContentModel {

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

  public init(cards: IdentifiedArrayOf<Card>) {
    self.cards = cards
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
    destination = nil
  }
}

@MainActor
public struct ContentView: View {
  @State var model: ContentModel

  public init(model: ContentModel) {
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
  func makeDestination(_ destination: ContentModel.Destination) -> some View {
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
  ContentView(model: .init( cards: cards))
}
