import UIKit
import Core

final class ToolbarRouter {
  
  private weak var rootController: UIViewController?

  init(rootController: UIViewController?) {
    self.rootController = rootController
  }

  func presentColorPicker(_ delegate: UIColorPickerViewControllerDelegate) {
      let controller = UIColorPickerViewController()
      controller.delegate = delegate
      rootController?.present(controller, animated: true)
  }

  func showNotImplementedAlert() {
    rootController?.presentAlert(
      message: "This feature not implemented yet",
      title: "Not implemented"
    )
  }

}
