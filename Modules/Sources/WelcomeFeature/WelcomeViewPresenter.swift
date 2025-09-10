import Core
import Foundation
import Photos

import class UIKit.UIApplication

final class WelcomePresenter {
  // MARK: - Propeties

  weak var view: WelcomeViewInput?

  private let onFinish: Command

  private var currentStatus: PHAuthorizationStatus {
    let readWriteStatus: PHAuthorizationStatus

    if #available(iOS 14, *) {
      readWriteStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    } else {
      readWriteStatus = PHPhotoLibrary.authorizationStatus()
    }

    return readWriteStatus
  }

  private let notDeterminedTitle = "Дать доступ"
  private let deniedTitle = "Открыть настройки"
  private let authorizedTitle = "Финиш"

  private var currentTitle: String {
    switch currentStatus {
    case .notDetermined:
      return notDeterminedTitle
    case .authorized, .limited:
      return authorizedTitle
    default:
      return deniedTitle
    }
  }

  // MARK: - init/deinit

  init(onFinish: Command) {
    self.onFinish = onFinish
  }

  // MARK: - Private methods

  private func handleAccess() {
    let fatalMessage = "Unkown case — PHAuthorizationStatus"
    let readWriteStatus = currentStatus

    switch readWriteStatus {
    case .authorized, .limited:
      onFinish.perform()
      return
    case .restricted, .denied:
      openAppSettings()
      return
    case .notDetermined:
      break
    @unknown default:
      fatalError(fatalMessage)
    }

    let handler: (PHAuthorizationStatus) -> Void = { [weak self] status in
      guard let self = self
      else { return }

      DispatchQueue.main.async { [weak self] in
        guard let self = self
        else { return }

        switch status {
        case .authorized, .limited:
          self.onFinish.perform()
          return
        case .restricted, .denied, .notDetermined:
          self.updateViewModel()
          return
        @unknown default:
          fatalError(fatalMessage)
        }
      }
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: handler)
    } else {
      PHPhotoLibrary.requestAuthorization(handler)
    }
  }

  private func openAppSettings() {
    let settingsURLString = UIApplication.openSettingsURLString

    guard let url = URL(string: settingsURLString),
          UIApplication.shared.canOpenURL(url)
    else { return }

    UIApplication.shared.open(url, options: [:])
  }

  private func updateViewModel() {
    let viewModel = createViewModel()
    view?.configure(with: viewModel)
  }

  private func createViewModel() -> WelcomeView.ViewModel {
    let title = currentTitle

    let onTap = Command { [weak self] in
      guard let self = self
      else { return }

      self.handleAccess()
    }

    return WelcomeView.ViewModel(
      title: title,
      onTap: onTap
    )
  }
}

// MARK: - WelcomeViewOutput

extension WelcomePresenter: WelcomeViewOutput {
  func onViewDidLoad() {
    updateViewModel()
  }
}
