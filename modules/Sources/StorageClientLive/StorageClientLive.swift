import StorageClient
import Foundation
import Dependencies

extension URL {
  fileprivate static let base = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.eden.documents"
  )!
}

extension StorageClient: DependencyKey {
  public static let liveValue = StorageClient(
    load: { key in
      try Data(contentsOf: URL.base.appendingPathComponent(key).appendingPathExtension("json"))
    },
    save: { data, key in
      try data.write(to: URL.base.appendingPathComponent(key).appendingPathExtension("json"))
    }
  )
}
