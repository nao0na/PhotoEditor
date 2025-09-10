import UIKit
import App

@main
final class Application {
  static func main() {
    UIApplicationMain(
      CommandLine.argc,
      CommandLine.unsafeArgv,
      nil,
      NSStringFromClass(AppDelegate.self)
    )
  }
}
