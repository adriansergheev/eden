import SwiftUI
import SwiftUINavigation

@MainActor
public let cards: [Card] = [
  .init(id: UUID(), title: "Claim your mornings", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit"),
  .init(id: UUID(), title: "Take control of Youtube", description: "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua", isSolved: true),
  .init(id: UUID(), title: "Instagram", description: "Coming soon...")
]

@MainActor
@Observable
public class ContentModel {
  @CasePathable
  enum Destination {
    case detail(Card)
  }
  var destination: Destination?
  var cards: [Card]

  public init(cards: [Card]) {
    self.cards = cards
  }

  func whyShouldYouCareButtonTapped(_ card: Card) {
    destination = .detail(card)
  }
}

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
                  secondaryAction: { model.whyShouldYouCareButtonTapped(card) }
                )
              }
            }
            Section {
              ForEach(model.cards.filter { $0.isSolved }) { card in
                CardView(card: card)
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
            }
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 8)
        }
      }
      .navigationTitle("Your iPhone")
      .background(Color(UIColor.systemGroupedBackground))
    }
    .sheet(item: $model.destination.detail) { _ in
      CardDetailView()
    }
  }
}

struct CardView: View {
  @Environment(\.colorScheme) var colorScheme
  let card: Card

  var secondaryAction: (() -> Void)?

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
          secondaryAction?()
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
        Spacer()
        Button(action: {
          // Resolve action
        }) {
          Text("Resolve")
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(8)
            .frame(minWidth: 80)
            .background(card.isSolved ? .gray : .green)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
    .disabled(card.isSolved)
  }
}

#Preview {
  ContentView(
    model: .init(cards: cards)
  )
}
