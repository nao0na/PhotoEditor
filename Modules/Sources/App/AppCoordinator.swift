import Core
import UIKit
import Photos

import WelcomeFeature
import PhotoPickerFeature
import EditorFeature
import ToolbarFeature

public final class AppCoordinator {
  // MARK: - Properties

  private let window: UIWindow

  private var topController: UIViewController? {
    return window.rootViewController
  }

  private var photoPickerController: PhotoPickerViewController?
  private var welcomeController: UIViewController?
  private var editorController: UIViewController?

  private var isAccessGranted: Bool {
    let status: PHAuthorizationStatus

    if #available(iOS 14, *) {
      status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    } else {
      status = PHPhotoLibrary.authorizationStatus()
    }

    switch status {
    case .authorized, .limited:
      return true
    default:
      return false
    }
  }

  // MARK: - init/deinit

  init(window: UIWindow) {
    self.window = window
  }

  // MARK: - Public methods

  func start() {
    showPhotoPicker()
    
    if isAccessGranted == false {
      showWelcome()
    }
  }

  // MARK: - Private methods

  private func showPhotoPicker() {
    let onImageTap: CommandWith<UIImage> = .init { [weak self] image in
      guard let self = self
      else { return }
      
      self.showEditor(with: image)
    }

    let onLossAccess: Command = .init { [weak self] in
      guard let self = self
      else { return }

      self.showWelcome()
    }

    let viewController = PhotoPickerViewController(
      onImageTap: onImageTap,
      onLossAccess: onLossAccess
    )

    window.rootViewController = viewController
    photoPickerController = viewController
  }

  private func showWelcome() {
    let onFinish = Command { [weak self] in
      guard let self = self
      else { return }

      self.photoPickerController?.reloadAssets { [weak self] in
        guard let self = self
        else { return }

        self.welcomeController?.dismiss(animated: true)
        self.welcomeController = nil
      }
    }

    let viewController = WelcomeViewController(
      onFinish: onFinish
    )

    topController?.present(viewController, animated: false)
    welcomeController = viewController
  }

  private func showEditor(with image: UIImage) {
    let viewController = EditorViewController(
      image: image,
      toolbarController: ToolbarViewController(),
      editorDelegate: self
    )
    viewController.modalPresentationStyle = .fullScreen
    
    topController?.present(viewController, animated: true)
    editorController = viewController
  }
}

// MARK: - EditorDelegate

extension AppCoordinator: EditorDelegate {
  public func editor(
    _ editor: EditorFeature.Editor,
    didFinishWith image: CGImage?
  ) {
    guard let cgImage = image else {
      editorController?.dismiss(animated: true)
      editorController = nil

      photoPickerController?.presentAlert(
        message: "Internal editor error",
        title: "Error"
      )
      return
    }

    let image = UIImage(cgImage: cgImage)

    photoPickerController?.saveToGallery(
      image: image
    ) { [weak self] result in
      guard let self = self
      else { return }

      self.editorController?.dismiss(animated: true)
      self.editorController = nil

      switch result {
      case .success(_):
        return
      case let .failure(error):
        self.photoPickerController?.presentAlert(
          message: "An error has occured while saving the image — \(error.localizedDescription)",
          title: "Error"
        )
      }
    }
  }

  public func editorDidCancel(_ editor: EditorFeature.Editor) {
    editorController?.dismiss(animated: true)
    editorController = nil
  }
}
