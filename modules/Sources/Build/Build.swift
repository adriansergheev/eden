import Foundation
import Dependencies
import XCTestDynamicOverlay

public struct Build {
  public var number: () -> Int?

  public init(number: @escaping () -> Int?) {
    self.number = number
  }
}

extension DependencyValues {
  public var build: Build {
    get { self[Build.self] }
    set { self[Build.self] = newValue }
  }
}

extension Build: TestDependencyKey {
  public static let previewValue = Self.noop

  public static let testValue = Self(
    number: unimplemented("\(Self.self).number", placeholder: 0)
  )
}

extension Build: DependencyKey {
  public static let liveValue = Self(
    number: {
      (Bundle.main.infoDictionary?["CFBundleVersion"] as? String).flatMap(Int.init)
    }
  )
}

extension Build {
  public static let noop = Self(
    number: { 0 }
  )
}

