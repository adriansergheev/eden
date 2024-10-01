import SwiftUI

struct CardDetailView: View {
  let card: Card
  var body: some View {
    Text(card.description)
  }
}
