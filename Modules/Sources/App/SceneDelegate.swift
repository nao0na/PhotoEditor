import UIKit

public final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  public var window: UIWindow?
  public var coordinator: AppCoordinator?

  public func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene)
    else { return }

    let window: UIWindow = .init(windowScene: windowScene)
    window.overrideUserInterfaceStyle = .dark
    window.makeKeyAndVisible()

    let coordinator: AppCoordinator = .init(window: window)
    coordinator.start()

    self.window = window
    self.coordinator = coordinator
  }
}
