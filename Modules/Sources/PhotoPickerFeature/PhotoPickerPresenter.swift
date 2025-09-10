import Foundation
import Photos
import Core

import class UIKit.UIImage

final class PhotoPickerPresenter {
  // MARK: - Properties

  weak var view: PhotoPickerViewInput?

  private let service: PhotoPickerService
  private let onImageTap: CommandWith<UIImage>
  private let onLossAccess: Command

  // MARK: - init/deinit

  init(
    service: PhotoPickerService,
    onImageTap: CommandWith<UIImage>,
    onLossAccess: Command
  ) {
    self.service = service
    self.onImageTap = onImageTap
    self.onLossAccess = onLossAccess
  }

  // MARK: - Private methods

  private func fetchAssets(_ completion: (() -> Void)? = nil) {
    service.fetchAssets { [weak self] assetItems in
      guard let self = self
      else { return }

      self.view?.configure(with: assetItems)
      completion?()
    }
  }
}

// MARK: - PhotoPickerViewOutput

extension PhotoPickerPresenter: PhotoPickerViewOutput {
  func didSellectImage(_ image: UIImage) {
    onImageTap.perform(with: image)
  }
  
  func onViewDidLoad() {
    fetchAssets()
  }
  
  func reloadAssets(_ completion: (() -> Void)?) {
    fetchAssets(completion)
  }

  func saveAsset(image: UIImage, completion: ((Result<Void, Error>) -> Void)?) {
    service.saveAsset(image: image, completion: completion)
  }

  func didLossAccess() {
    onLossAccess.perform()
  }
}
