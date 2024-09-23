import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct DataManager: Sendable {
  public var load: @Sendable (_ from: URL) throws -> Data
  public var save: @Sendable (Data, _ to: URL) throws -> Void
}

extension DependencyValues {
  public var dataManager: DataManager {
    get { self[DataManager.self] }
    set { self[DataManager.self] = newValue }
  }
}

extension DataManager: TestDependencyKey {
  public static var testValue: DataManager { Self.mock() }

  public static func mock(initialData: Data? = nil) -> DataManager {
    let data = LockIsolated(initialData)
    return DataManager(
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

  public static let failToWrite = DataManager(
    load: { url in Data() },
    save: { data, url in
      struct SaveError: Error {}
      throw SaveError()
    }
  )

  public static let failToLoad = DataManager(
    load: { _ in
      struct LoadError: Error {}
      throw LoadError()
    },
    save: { newData, url in }
  )
}
