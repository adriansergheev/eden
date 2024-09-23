import Dependencies
import DependenciesMacros
import Foundation
import FamilyControls

@DependencyClient
struct AuthorizationCenterManager: Sendable {
  var requestAuthorization: @Sendable () async throws -> Void
}

extension AuthorizationCenterManager: DependencyKey {
  static let liveValue = AuthorizationCenterManager(
    requestAuthorization: {
      let authorizationCenter = AuthorizationCenter.shared
      try await authorizationCenter.requestAuthorization(
        for: .individual
      )
    }
  )
  static let testValue = AuthorizationCenterManager()
}

extension DependencyValues {
  var authorizationCenter: AuthorizationCenterManager {
    get { self[AuthorizationCenterManager.self] }
    set { self[AuthorizationCenterManager.self] = newValue }
  }
}
