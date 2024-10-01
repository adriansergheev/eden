import SwiftUI
import AVKit
import Dependencies
import IssueReporting

@MainActor
@Observable
final class TutorialModel {
  @ObservationIgnored
  var onTutorialCompleted: ((Card) -> Void)
  private(set) var player: AVPlayer?

  var card: Card

  @ObservationIgnored
  @Dependency(\.continuousClock) var clock

  init(card: Card, onTutorialCompleted: @escaping (Card) -> Void = unimplemented("onTutorialCompleted")) {
    self.card = card
    self.onTutorialCompleted = onTutorialCompleted
  }

  func task() async {
    let resourceName = card.title.replacingOccurrences(of: " ", with: "-").lowercased()
    guard let url = Bundle.module.url(forResource: resourceName, withExtension: "mp4")
    else { return }

    self.player = AVPlayer(url: url)
    try? await clock.sleep(for: .seconds(1))
    player?.play()
  }

  func markAsResolvedTapped() {
    card.status = .solved(true)
    onTutorialCompleted(card)
  }
}

struct TutorialView: View {
  let model: TutorialModel

  var body: some View {
    VStack {
      if let player = model.player {
        VideoPlayer(player: player)
      } else {
        //TODO: Error handling
        Spacer()
      }

      Button {
        model.markAsResolvedTapped()
      } label: {
        Text("Mark as resolved")
          .foregroundColor(Color.green)
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color.green.opacity(0.1))
          .cornerRadius(12)
          .padding()
      }

    }
    .task {
      await model.task()
    }
  }
}

#Preview {
  TutorialView(
    model: .init(
      card: .init(
        id: .init(),
        title: "test card",
        description: "test description",
        target: .tutorial,
        status: .solved(false)
      )
    )
  )
}
