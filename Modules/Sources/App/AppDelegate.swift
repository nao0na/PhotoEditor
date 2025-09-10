import UIKit
import Lottie

public final class AppDelegate: UIResponder, UIApplicationDelegate {

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    setupLottie()
    return true
  }

  // MARK: - UISceneSession Lifecycle

  public func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    guard connectingSceneSession.role == UISceneSession.Role.windowApplication
    else { fatalError("Unhandled scene role \(connectingSceneSession.role)") }

    let config: UISceneConfiguration = .init(
      name: nil,
      sessionRole: connectingSceneSession.role
    )
    config.delegateClass = SceneDelegate.self
    return config
  }

  // MARK: - Private methods

  private func setupLottie() {
    LottieConfiguration.shared.renderingEngine = .automatic
    LottieConfiguration.shared.decodingStrategy = .codable
  }
}
