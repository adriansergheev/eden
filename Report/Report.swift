import DeviceActivity
import SwiftUI

@main
struct Report: DeviceActivityReportExtension {
  var body: some DeviceActivityReportScene {
    // Create a report for each DeviceActivityReport.Context that your app supports.
    TotalActivityReport { totalActivity in
      TotalActivityView(totalActivity: totalActivity)
    }
    // Add more reports here...
  }
}

struct TotalActivityView: View {
  let totalActivity: String

  var body: some View {
    Text(totalActivity)
      .border(.red)
  }
}

// In order to support previews for your extension's custom views, make sure its source files are
// members of your app's Xcode target as well as members of your extension's target. You can use
// Xcode's File Inspector to modify a file's Target Membership.
#Preview {
  TotalActivityView(totalActivity: "1h 23m")
}
