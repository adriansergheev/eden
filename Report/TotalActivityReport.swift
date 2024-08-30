import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
  // If your app initializes a DeviceActivityReport with this context, then the system will use
  // your extension's corresponding DeviceActivityReportScene to render the contents of the
  // report.
  static let totalActivity = Self("Total Activity")
}

struct Activity: Hashable {
  let categoryNames: [String]
  let totalDuration: String
}

struct TotalActivityReport: DeviceActivityReportScene {
  // Define which context your scene will represent.
  let context: DeviceActivityReport.Context = .totalActivity

  // Define the custom configuration and the resulting view for this report.
  let content: ([Activity]) -> TotalActivityView

  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> [Activity] {
    // Reformat the data into a configuration that can be used to create
    // the report's view.
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .dropAll

//    let totalActivityDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
//      $0 + $1.totalActivityDuration
//    })
//    return formatter.string(from: totalActivityDuration) ?? "No activity

    return await data.flatMap { $0.activitySegments }
      .map { activitySegment -> Activity in
        var categoryNames: [String] = []
        let segment = activitySegment.categories

        for await activity in segment {
          guard let categoryName = activity.category.localizedDisplayName
          else { break }
          categoryNames.append(categoryName)
        }
        let duration = activitySegment.totalActivityDuration
        let formattedDuration = formatter.string(from: duration) ?? "No Activity"
        return Activity(
          categoryNames: categoryNames,
          totalDuration: formattedDuration
        )
//        return (categoryNames, formattedDuration)
      }.reduce(into: []) { partialResult, activity in
        partialResult.append(activity)
      }
  }
}

