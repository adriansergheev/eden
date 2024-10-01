import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct StorageClient: Sendable {
  public var load: @Sendable (_ from: String) throws -> Data
  public var save: @Sendable (Data, _ to: String) throws -> Void
}

extension DependencyValues {
  public var storageClient: StorageClient {
    get { self[StorageClient.self] }
    set { self[StorageClient.self] = newValue }
  }
}

extension StorageClient: TestDependencyKey {
  public static var testValue: StorageClient { Self.mock() }

  public static func mock(initialData: Data? = nil) -> StorageClient {
    let data = LockIsolated(initialData)
    return StorageClient(
      load: { _ in
        guard let data = data.value
        else {
          struct FileNotFound: Error {}
          throw FileNotFound()
        }
        return data
      },
      save: { newData, _ in data.setValue(newData) }
    )
  }

  public static let failToWrite = StorageClient(
    load: { _ in Data() },
    save: { _, _ in
      struct SaveError: Error {}
      throw SaveError()
    }
  )

  public static let failToLoad = StorageClient(
    load: { _ in
      struct LoadError: Error {}
      throw LoadError()
    },
    save: { _, _ in }
  )
}
