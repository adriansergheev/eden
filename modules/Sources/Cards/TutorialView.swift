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

  private(set) var player: AVPlayer?

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
    try? await clock.sleep(for: .milliseconds(50))
    player?.play()
    try? await clock.sleep(for: .milliseconds(300))
    player?.pause()
  }

  func togglePlay() {
    guard let player else { return }
    isPlaying ? player.pause() : player.play()
    isPlaying.toggle()
//    player.seek(to: .zero)
  }
}

struct TutorialView: View {
  let model: TutorialModel

  var body: some View {
    VStack {
      if let player = model.player {
        VideoPlayer(player: player)
        Button {
          model.togglePlay()
        } label: {
          Image(systemName: model.isPlaying ? "stop" : "play")
            .padding()
            .tint(.green)
        }
      } else {
        //TODO: Error handling
      }
    }
    .task {
      await model.task()
    }
  }
}
