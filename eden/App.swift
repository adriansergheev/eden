import SwiftUI
import Cards

@main
struct EdenApp: App {
  var body: some Scene {
    WindowGroup {
      CardsView(
        model: .init(cards: cards)
      )
    }
  }
}
