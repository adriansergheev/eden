import UIKit
import Dependencies
import XCTestDynamicOverlay

public struct UIApplicationClient {
  public var open: @Sendable (URL, [UIApplication.OpenExternalURLOptionsKey: Any]) async -> Bool
  //  public var openSettingsURLString: @Sendable () async -> String
  //  public var setUserInterfaceStyle: @Sendable (UIUserInterfaceStyle) async -> Void
}

extension UIApplicationClient: DependencyKey {
  public static let liveValue = Self(
    open: { @MainActor in await UIApplication.shared.open($0, options: $1) }
    //    openSettingsURLString: { await UIApplication.openSettingsURLString },
    //    setUserInterfaceStyle: { userInterfaceStyle in
    //      await MainActor.run {
    //        guard
    //          let scene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene })
    //            as? UIWindowScene
    //        else { return }
    //        scene.keyWindow?.overrideUserInterfaceStyle = userInterfaceStyle
    //      }
    //    }
  )
}

extension DependencyValues {
  public var applicationClient: UIApplicationClient {
    get { self[UIApplicationClient.self] }
    set { self[UIApplicationClient.self] = newValue }
  }
}

extension UIApplicationClient: TestDependencyKey {
  public static let previewValue = Self.noop

  public static let testValue = Self(
    open: unimplemented("\(Self.self).open", placeholder: false)
    //    openSettingsURLString: unimplemented("\(Self.self).openSettingsURLString"),
    //    setUserInterfaceStyle: unimplemented("\(Self.self).setUserInterfaceStyle")
  )
}

extension UIApplicationClient {
  public static let noop = Self(
    open: { _, _ in false }
    //    openSettingsURLString: { },
    //    setUserInterfaceStyle: { _ in }
  )
}
