import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    // Customize the shield as needed for applications.
    let configuration = ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: .black,
      icon: nil,
      title: .init(text: "✋", color: .white),
      subtitle: nil,
      primaryButtonLabel: nil,
      primaryButtonBackgroundColor: .green,
      secondaryButtonLabel: nil
    )
    return configuration
  }

  override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
    // Customize the shield as needed for applications shielded because of their category.
    ShieldConfiguration()
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    // Customize the shield as needed for web domains.
    ShieldConfiguration()
  }

  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
    // Customize the shield as needed for web domains shielded because of their category.
    ShieldConfiguration()
  }
}
