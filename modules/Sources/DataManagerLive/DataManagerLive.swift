import DataManager
import Foundation
import Dependencies

extension DataManager: DependencyKey {
  public static let liveValue = DataManager(
    load: { url in try Data(contentsOf: url) },
    save: { data, url in try data.write(to: url) }
  )
}
