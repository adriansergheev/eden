import SwiftUI

struct CardDetailView: View {
  let card: Card
  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text(card.title)
          .font(.title3)
          .padding(.bottom)
        Text("What's that?")
          .font(.title)
        Divider()
        Text(card.body)
        Divider()
      }
      HStack {
        ForEach(0..<3) { _ in
          Image(systemName: "grid")
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.green.opacity(0.7))
            .frame(width: 16, height: 16)
        }
      }
      Spacer()
    }
    .padding()
  }
}

#Preview {
  CardDetailView(
    card: .init(
      id: .init(),
      title: "Claim your evenings.",
      description: "You deserve to unwind.",
      body: """
Reclaiming your evenings means consciously limiting distractions and dedicating time to unwind and do what truly matters to you.

Evenings are often stolen by endless scrolling and notifications. Taking control of this time can improve your overall well-being.
""",
      target: .screenTime(.morning),
      status: .solved(false)
    )
  )
}
