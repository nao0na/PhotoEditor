import UIKit

public extension UIViewController {
  
  func presentAlert(message: String, title: String, buttonTitle: String = "Dismiss") {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.init(title: buttonTitle, style: .default, handler: { [weak alertController] _ in
      alertController?.dismiss(animated: true)
    }))
    present(alertController, animated: true)
  }
  
}
