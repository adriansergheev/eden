import SwiftUI

//TODO: move
extension CGFloat {
  public static func grid(_ n: Int) -> Self { Self(n) * 4.0 }
}

@MainActor
@Observable
public class SettingsModel {

  init() {

  }

  func shareIdeasButtonTapped() {

  }

  func leaveAReviewButtonTapped() {

  }

  func joinOurDiscordButtonTapped() {

  }

  func termsAndPrivacyButtonTapepd() {

  }
}

public struct SettingsView: View {
  let model: SettingsModel
  @Environment(\.colorScheme) var colorScheme

  init(model: SettingsModel) {
    self.model = model
  }

  public var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: .grid(2)) {
        VStack(spacing: .grid(8)) {
          Cell {
            Button {
              model.shareIdeasButtonTapped()
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
              model.termsAndPrivacyButtonTapepd()
            } label: {
              Label(text: "Terms / Privacy")
            }
          }
          .disabled(true)
        }
        .padding(.grid(4))

        VStack(alignment: .leading, spacing: .grid(1)) {
          //              if let buildNumber = self.viewStore.buildNumber {
          //                Text("Build \(buildNumber.rawValue)")
          //                  .fontWeight(.thin)
          //                  .multilineTextAlignment(.leading)
          //                  .font(.footnote)
          //              }
          Button {
            //                viewStore.send(.reportABugButtonTapped)
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
    .background(colorScheme == .light ? Color.gray.opacity(0.2) : .black)
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
