import SwiftUI
import ComposableArchitecture

public let cards: [Card] = [
  .init(title: "Claim your mornings", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit"),
  .init(title: "Take control of Youtube", description: "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"),
  .init(title: "Title 3", description: "Subtitle 3")
]

@Reducer
public struct Content {
  @ObservableState
  public struct State: Equatable {
    var cards: [Card]
    public init(cards: [Card]) {
      self.cards = cards
    }
  }

  public init () {}
}

public struct ContentView: View {
  @Bindable var store: StoreOf<Content>

  public init(store: StoreOf<Content>) {
    self.store = store
  }

  public var body: some View {
    NavigationView {
      VStack {
        HStack {
          Text("Audited for productivity")
            .font(.title)
          Spacer()
        }
        .padding(.horizontal)
        ScrollView {
          ForEach(store.cards, id: \.self) { card in
            CardView(card: card)
          }
          .padding(.vertical)
          .padding(.horizontal, 8)
        }
      }
      .navigationTitle("Your iPhone")
      .background(Color(UIColor.systemGroupedBackground))
    }
  }
}

struct CardView: View {
  @Environment(\.colorScheme) var colorScheme
  let card: Card

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
          // Why you should care action
        }) {
          HStack {
            Image(systemName: "play.circle.fill")
              .foregroundColor(.green)
            Text("Why you should care")
              .font(.subheadline)
              .foregroundColor(.green)
          }
          .padding(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.green, lineWidth: 1)
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
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding()
    .background(colorScheme == .light ? Color.white : nil)
    .clipShape(RoundedRectangle(cornerRadius: 15))
    .shadow(radius: 5)
    .padding(.horizontal)
  }
}

#Preview {
  ContentView(
    store: .init(
      initialState: Content.State(cards: cards),
      reducer: { Content() }
    )
  )
}
