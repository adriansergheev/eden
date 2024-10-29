import SwiftUI
import Build
import Dependencies
import UIApplicationClient

//TODO: move
extension CGFloat {
  public static func grid(_ n: Int) -> Self { Self(n) * 3.0 }
}

@MainActor
@Observable
public class SettingsModel: Identifiable {
  @ObservationIgnored
  @Dependency(\.build) var build
  @ObservationIgnored
  @Dependency(\.applicationClient) var applicationClient

  public init() {

  }

  func shareIdeasButtonTapped() async {
    await composeEmail(subject: "I would like to share some ideas")
  }

  func leaveAReviewButtonTapped() {

  }

  func joinOurDiscordButtonTapped() {

  }

  func termsAndPrivacyButtonTapped() {

  }

  func reportABugButtonTapped() async {
    await composeEmail(subject: "I found a bug in Clario")
  }

  private func composeEmail(subject: String) async {
    var components = URLComponents()
    components.scheme = "mailto"
    components.path = "sergheevdev@icloud.com"
    components.queryItems = [
      URLQueryItem(name: "subject", value: subject),
      URLQueryItem(
        name: "body",
        value: """
---
Build: \(String(describing: self.build.number()))
"""
      )
    ]

    _ = await self.applicationClient.open(components.url!, [:])
  }
}

public struct SettingsView: View {
  @State var model: SettingsModel
  @Environment(\.colorScheme) var colorScheme

  public init(model: SettingsModel) {
    self.model = model
  }

  public var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: .grid(2)) {
        VStack(spacing: .grid(8)) {
          Cell {
            Button {
              Task { await model.shareIdeasButtonTapped() }
            } label: {
              Label(text: "Share Ideas")
            }
          }
          Cell {
            Button {
              model.leaveAReviewButtonTapped()
            } label: {
              Label(text: "Leave a review")
            }
          }
          .disabled(true)
          Cell {
            Button {
              model.joinOurDiscordButtonTapped()
            } label: {
              Label(text: "Join our Discord")
            }
          }
          .disabled(true)
          Cell {
            Button {
              model.termsAndPrivacyButtonTapped()
            } label: {
              Label(text: "Terms / Privacy")
            }
          }
          .disabled(true)
        }
        .padding(.grid(4))

        VStack(alignment: .leading, spacing: .grid(1)) {
          if let buildNumber = model.build.number() {
            Text("Build \(buildNumber)")
              .fontWeight(.thin)
              .multilineTextAlignment(.leading)
              .font(.footnote)
          }
          Button {
            Task { await model.reportABugButtonTapped() }
          } label: {
            Text("Report a bug")
              .fontWeight(.thin)
              .underline()
              .font(.footnote)
              .tint(colorScheme == .dark ? .white : .black)
            Spacer()
          }
        }
        .padding()
        Spacer()
      }
    }
    .padding(.grid(4))
    .tint(.green.opacity(0.9))
  }
}

struct Label: View {
  let text: String
  @Environment(\.colorScheme) var colorScheme
  init(text: String) {
    self.text = text
  }
  var body: some View {
    Text(text)
      .tint(colorScheme == .dark ? .white : .black)
    Spacer()
    Image(systemName: "arrow.right")
      .tint(.green)
      .padding(.trailing, .grid(1))
  }
}


struct Cell<Content: View>: View {
  var content: () -> Content
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  var body: some View {
    ZStack {
      VStack(alignment: .leading, spacing: .grid(2)) {
        self.content()
        Divider()
          .background(Color.black)
          .frame(height: 2)
      }
    }
  }
}

#Preview {
  SettingsView(model: .init())
}
