import SwiftUI
import Cards
import Dependencies

@main
struct EdenApp: App {
  var body: some Scene {
    WindowGroup {
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        NavigationStack {
          CardsView(model: .init())
        }
      }
    }
  }
}
