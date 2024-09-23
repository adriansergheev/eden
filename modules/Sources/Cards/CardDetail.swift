import SwiftUI
import DeviceActivity

// TODO: DeviceActivityReport not needed for mvp, provide some text instead.
// extension DeviceActivityReport.Context {
//  static let totalActivity = Self.init("Total Activity")
// }

struct ScreenTimeCardDetailView: View {
//  @State private var context: DeviceActivityReport.Context = .totalActivity
//  @State private var filter = DeviceActivityFilter(
//    segment: .daily(
//      during: DateInterval(
//        start: Date(timeIntervalSinceNow: -7 * 24 * 60 * 60),
//        end: Date()
//      )
//    )
//  )
  var body: some View {
    VStack {
//      GeometryReader { geometry in
//        VStack(alignment: .leading) {
//          DeviceActivityReport(context)
//            .frame(height: geometry.size.height * 0.75)
//        }
//        .border(.red)
//      }
      Text(
        "Think about the amount of time spent every morning on things which don't matter."
      )
    }
  }
}
