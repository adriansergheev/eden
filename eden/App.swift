import SwiftUI
import Content

@main
struct EdenApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(
        store: .init(
          initialState: Content.State(cards: cards),
          reducer: { Content() }
        )
      )
    }
  }
}
