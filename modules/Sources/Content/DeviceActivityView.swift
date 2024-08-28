import SwiftUI
import DeviceActivity // execute code on usage treshold

extension DeviceActivityReport.Context {
  static let totalActivity = Self.init("Total Activity")
}

struct DeviceActivityView: View {
  @State private var context: DeviceActivityReport.Context = .totalActivity
  @State private var filter = DeviceActivityFilter(segment: .daily(during: DateInterval(start: Date(timeIntervalSinceNow: -7 * 24 * 60 * 60), end: Date())))
  
  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .leading) {
        DeviceActivityReport(context)
          .frame(height: geometry.size.height * 0.75)
      }
      .border(.red)
    }
  }
}
