import Foundation
import Photos

import class UIKit.UIImage

final class AssetItem {
  // MARK: - Public properties

  let asset: PHAsset

  var mediaType: PHAssetMediaType {
    return asset.mediaType
  }

  var duration: TimeInterval? {
    guard mediaType == .video
    else { return nil }

    return asset.duration
  }

  // MARK: - Private properties

  private let queue: DispatchQueue
  private let imageManager: PHImageManager

  // MARK: - init/deinit

  init(
    asset: PHAsset,
    queue: DispatchQueue,
    imageManager: PHImageManager
  ) {
    self.asset = asset
    self.queue = queue
    self.imageManager = imageManager
  }

  // MARK: - Public methods

  func fetchThumb(
    for size: CGSize,
    completion: @escaping (UIImage?) -> Void
  ) -> UIImage? {
    var syncedImage: UIImage?
    var hasLoadedImage = false

    imageManager.requestImage(
      for: asset,
      targetSize: size,
      contentMode: .aspectFill,
      options: nil
    ) { image, _ in
      syncedImage = image
      
      if hasLoadedImage == false || image != nil {
        completion(image)
        
        if image != nil {
          hasLoadedImage = true
        }
      }
    }

    return syncedImage
  }
  
  func fetchFullSizeImage(
    completion: @escaping (UIImage) -> Void
  ) {
    let targetSize = PHImageManagerMaximumSize
    
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    options.isNetworkAccessAllowed = false
    options.deliveryMode = .highQualityFormat

    queue.async { [weak self] in
      guard let self = self
      else { return }

      self.imageManager.requestImage(
        for: self.asset,
        targetSize: targetSize,
        contentMode: .aspectFill,
        options: options
      ) { image, _ in
        guard let image = image
        else { return }

        guard let jpegData = image.jpegData(compressionQuality: 1),
              let jpegImage = UIImage(data: jpegData)
        else {
          DispatchQueue.main.async {
            completion(image)
          }
          return
        }

        DispatchQueue.main.async {
          completion(jpegImage)
        }
      }
    }
  }
}

// MARK: - PhotoPickerService

protocol PhotoPickerService: AnyObject {
  func fetchAssets(completion: (([AssetItem]) -> Void)?)
  func saveAsset(image: UIImage, completion: ((Result<Void, Error>) -> Void)?)
}

final class PhotoPickerServiceImpl: PhotoPickerService {
  // MARK: - Properties

  private let queue: DispatchQueue
  private let imageManager: PHImageManager
  
  private var currentStatus: PHAuthorizationStatus {
    let readWriteStatus: PHAuthorizationStatus

    if #available(iOS 14, *) {
      readWriteStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    } else {
      readWriteStatus = PHPhotoLibrary.authorizationStatus()
    }

    return readWriteStatus
  }
  
  private var canFetch: Bool {
    switch currentStatus {
    case .authorized, .limited:
      return true
    default:
      return false
    }
  }

  private lazy var fetchOptions: PHFetchOptions = {
    let options = PHFetchOptions()
    options.sortDescriptors = [
      NSSortDescriptor.init(key: "creationDate", ascending: false)
    ]
    options.predicate = NSPredicate(
      format: "mediaType == %d",
      PHAssetMediaType.image.rawValue
    )
    return options
  }()

  // MARK: - init/deinit

  init() {
    self.queue = DispatchQueue(
      label: Constants.queueName,
      qos: .userInteractive
    )
    self.imageManager = PHCachingImageManager()
  }

  // MARK: - PhotoPickerService

  func fetchAssets(completion: (([AssetItem]) -> Void)?) {
    guard canFetch == true
    else { return }
    
    queue.async { [weak self] in
      guard let self = self
      else { return }

      let fetchResult = PHAsset.fetchAssets(
        with: self.fetchOptions
      )
      let count = fetchResult.count

      var assets: [AssetItem] = []

      for index in (0 ..< count) {
        let asset = fetchResult.object(at: index)

        assets.append(AssetItem(
          asset: asset,
          queue: self.queue,
          imageManager: self.imageManager
        ))
      }

      DispatchQueue.main.async {
        completion?(assets)
      }
    }
  }

  func saveAsset(
    image: UIImage,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    PHPhotoLibrary.shared().performChanges {
      _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
    } completionHandler: { isSuccess, error in
      guard isSuccess == true, error == nil else {
        let error = error ?? ServiceError()

        DispatchQueue.main.async {
          completion?(.failure(error))
        }

        return
      }

      DispatchQueue.main.async {
        completion?(.success(()))
      }
    }
  }
}

// MARK: - Constants

extension PhotoPickerServiceImpl {
  enum Constants {
    static var queueName: String {
      return """
      PhotoPickerFeature.PhotoPickerService.serial_queue
      """
    }
  }
}

// MARK: - ServiceError

extension PhotoPickerServiceImpl {
  struct ServiceError: Error, LocalizedError {
    var errorDescription: String? {
      return "Unknown error"
    }
  }
}
