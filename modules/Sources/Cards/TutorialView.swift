import SwiftUI
import AVKit
import Dependencies
import IssueReporting

@MainActor
@Observable
final class TutorialModel {
  @ObservationIgnored
  var onTutorialCompleted: ((Card) -> Void)

  var isPlaying: Bool = false
  var card: Card

  private(set) var player = AVPlayer(
    url: Bundle.module.url(forResource: "youtube-resolve", withExtension: "mp4")!
  )

  @ObservationIgnored
  @Dependency(\.continuousClock) var clock

  init(card: Card, onTutorialCompleted: @escaping (Card) -> Void = unimplemented("onTutorialCompleted")) {
    self.card = card
    self.onTutorialCompleted = onTutorialCompleted
  }

  func task() async {
    try? await clock.sleep(for: .milliseconds(50))
    player.play()
    try? await clock.sleep(for: .milliseconds(300))
    player.pause()
  }

  func togglePlay() {
    isPlaying ? player.pause() : player.play()
    isPlaying.toggle()
    player.seek(to: .zero)
  }
}

struct TutorialView: View {
  let model: TutorialModel

  var body: some View {
    VStack {
      VideoPlayer(player: model.player)
      Button {
        model.togglePlay()
      } label: {
        Image(systemName: model.isPlaying ? "stop" : "play")
          .padding()
      }
    }
    .task {
      await model.task()
    }
  }
}
