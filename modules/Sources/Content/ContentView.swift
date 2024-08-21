import SwiftUI
import ComposableArchitecture

struct CardView: View {
  @Environment(\.colorScheme) var colorScheme

  var title: String
  var description: String
  var imageName: String

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(title)
          .font(.headline)
          .foregroundColor(.primary)
        Spacer()
        //        Button(action: {
        //          // Close action
        //        }) {
        //          Image(systemName: "xmark")
        //            .foregroundColor(.gray)
        //        }
      }
      .padding(.bottom, 2)

      Text(description)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.bottom, 8)

      HStack {
        Button(action: {
          // Why you should care action
        }) {
          HStack {
            Image(systemName: "play.circle.fill")
              .foregroundColor(.green)
            Text("Why you should care")
              .font(.subheadline)
              .foregroundColor(.green)
          }
          .padding(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.green, lineWidth: 1)
          )
        }
        Spacer()
        Button(action: {
          // Resolve action
        }) {
          Text("Resolve")
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(8)
            .frame(minWidth: 80)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }

      .frame(maxWidth: .infinity)
    }
    .padding()
    .background(colorScheme == .light ? Color.white : nil)
    .clipShape(RoundedRectangle(cornerRadius: 15))
    .shadow(radius: 5)
    .padding(.horizontal)
  }
}
public struct ContentView: View {

  let items = [
    ("Claim your mornings", "Lorem ipsum dolor sit amet, consectetur adipiscing elit"),
    ("Take control of Youtube", "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"),
    ("Title 3", "Subtitle 3")
  ]

  public init() {}

  public var body: some View {
    NavigationView {
      VStack {
        HStack {
          Text("Audited for productivity")
            .font(.title)
          Spacer()
        }
        .padding(.horizontal)
        ScrollView {
          ForEach(items, id: \.0) { item in
            CardView(
              title: item.0,
              description: item.1,
              imageName: "person.crop.circle.fill.badge.checkmark"
            )
          }
          .padding(.vertical)
          .padding(.horizontal, 8)
        }
      }
      .navigationTitle("Your iPhone")
      .background(Color(UIColor.systemGroupedBackground))
    }
  }
}

#Preview {
  ContentView()
}
