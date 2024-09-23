import DeviceActivity
import SwiftUI

// TODO: Figure out if needed for prototype.

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
  let totalActivity: [Activity]

  var body: some View {
    List {
      ForEach(totalActivity, id: \.self) { activity in
        Text("\(activity.totalDuration)")
        Text("\(activity.categoryNames.reduce("", +))")
      }
    }
  }
}

// In order to support previews for your extension's custom views, make sure its source files are
// members of your app's Xcode target as well as members of your extension's target. You can use
// Xcode's File Inspector to modify a file's Target Membership.
#Preview {
  TotalActivityView(
    totalActivity: [.init(
      categoryNames: ["Entertainment"],
      totalDuration: "300 hours"
    )]
  )
}
