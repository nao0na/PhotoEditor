import UIKit
import Photos
import Core

protocol PhotoPickerViewInput: AnyObject {
  func configure(with assetItems: [AssetItem])
}

protocol PhotoPickerViewOutput: AnyObject {
  func onViewDidLoad()
  func reloadAssets(_ completion: (() -> Void)?)
  func saveAsset(image: UIImage, completion: ((Result<Void, Error>) -> Void)?)
  func didSellectImage(_ image: UIImage)
  func didLossAccess()
}

public final class PhotoPickerViewController: UIViewController {
  // MARK: - Subviews

  private lazy var mainView: PhotoPickerView = .init(
    frame: .zero
  )

  // MARK: - Properties

  private let viewOutput: PhotoPickerViewOutput
  private var assetItems: [AssetItem] = []

  private var transitionLayout: UICollectionViewLayout?

  // MARK: - init/deinit

  public init(
    onImageTap: CommandWith<UIImage>,
    onLossAccess: Command
  ) {
    let service = PhotoPickerServiceImpl()
    let presenter = PhotoPickerPresenter(
      service: service,
      onImageTap: onImageTap,
      onLossAccess: onLossAccess
    )
    self.viewOutput = presenter

    super.init(nibName: nil, bundle: nil)

    presenter.view = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - VC lifecycle

  public override func loadView() {
    view = mainView
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    setup()
    setupNotifications()

    viewOutput.onViewDidLoad()
  }

  // MARK: - Public methods

  public func reloadAssets(completion: (() -> Void)?) {
    viewOutput.reloadAssets(completion)
  }

  public func saveToGallery(
    image: UIImage,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    viewOutput.saveAsset(image: image) { [weak self] result in
      guard let self = self
      else { return }

      switch result {
      case .success(_):
        completion?(.success(()))
        break
      case let .failure(error):
        completion?(.failure(error))
        return
      }

      self.performUpdateGallery()
    }
  }

  // MARK: - Private methods

  private func setup() {
    mainView.collectionView.delegate = self
    mainView.collectionView.dataSource = self

    mainView.collectionView.register(
      PhotoPickerCollectionViewCell.self,
      forCellWithReuseIdentifier: PhotoPickerCollectionViewCell.identifier
    )

    mainView.nextCollectionView.delegate = self
    mainView.nextCollectionView.dataSource = self

    mainView.nextCollectionView.register(
      PhotoPickerCollectionViewCell.self,
      forCellWithReuseIdentifier: PhotoPickerCollectionViewCell.identifier
    )

    mainView.previousCollectionView.delegate = self
    mainView.previousCollectionView.dataSource = self

    mainView.previousCollectionView.register(
      PhotoPickerCollectionViewCell.self,
      forCellWithReuseIdentifier: PhotoPickerCollectionViewCell.identifier
    )
  }

  private func setupNotifications() {
//    NotificationCenter.default.addObserver(
//      self,
//      selector: #selector(PhotoPickerViewController.performUpdateGallery),
//      name: UIApplication.willEnterForegroundNotification,
//      object: nil
//    )
//    PHPhotoLibrary.shared().register(self)
  }

  @objc private func performUpdateGallery() {
    if assetItems.count > 0 {
      mainView.collectionView.scrollToItem(
        at: IndexPath(row: 0, section: 0),
        at: .top,
        animated: true
      )
    }

    viewOutput.reloadAssets(nil)
  }
}

// MARK: - PhotoPickerViewInput

extension PhotoPickerViewController: PhotoPickerViewInput {
  func configure(with assetItems: [AssetItem]) {
    self.assetItems = assetItems

    mainView.collectionView.reloadData()
    mainView.nextCollectionView.reloadData()
    mainView.previousCollectionView.reloadData()
  }
}

// MARK: - PHPhotoLibraryAvailabilityObserver

extension PhotoPickerViewController: PHPhotoLibraryAvailabilityObserver {
  public func photoLibraryDidBecomeUnavailable(
    _ photoLibrary: PHPhotoLibrary
  ) {
    CFRunLoopPerformBlock(
      CFRunLoopGetMain(),
      CFRunLoopMode.defaultMode.rawValue,
      { [weak self] in
        guard let self = self
        else { return }

        self.viewOutput.didLossAccess()
      }
    )
  }
}

// MARK: - UICollectionViewDataSource

extension PhotoPickerViewController: UICollectionViewDataSource {
  public func numberOfSections(
    in collectionView: UICollectionView
  ) -> Int {
    return 1
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return assetItems.count
  }
  
  public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: PhotoPickerCollectionViewCell.identifier,
      for: indexPath
    )

    if let photoPickerCell = cell as? PhotoPickerCollectionViewCell {
      let item = assetItems[indexPath.row]
      photoPickerCell.configure(
        with: item,
        targetSize: mainView.imageTargetSize
      )
    }

    return cell
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    if let photoPickerCell = cell as? PhotoPickerCollectionViewCell {
      let item = assetItems[indexPath.row]
      photoPickerCell.configure(
        with: item,
        targetSize: mainView.imageTargetSize
      )
    }
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PhotoPickerViewController: UICollectionViewDelegate {
  public func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    guard collectionView === mainView.collectionView
    else { return }

    let assetItem = assetItems[indexPath.row]
    assetItem.fetchFullSizeImage { [weak self] image in
      guard let self = self
      else { return }
      
      self.viewOutput.didSellectImage(image)
    }
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    handleBlurView(scrollView)
    scrollHiddenCollectionsView(scrollView)
  }

  // MARK: - Private

  private func handleBlurView(_ scrollView: UIScrollView) {
    guard scrollView === mainView.collectionView
    else { return }

    let targetOffsetY: CGFloat = 44
    let offsetY = scrollView.contentOffset.y

    if offsetY < 0 {
      mainView.blurView.alpha = 0
      return
    }

    if offsetY > targetOffsetY {
      mainView.blurView.alpha = 1
      return
    }

    let progress = offsetY / targetOffsetY
    let alpha = interpolate(from: .zero, to: 1, progress: progress)

    mainView.blurView.alpha = alpha
  }

  private func scrollHiddenCollectionsView(_ scrollView: UIScrollView) {
    guard scrollView === mainView.collectionView
    else { return }

    DispatchQueue.main.asyncDeduped(
      target: self,
      after: 0.1
    ) {
      let nextCollection = self.mainView.nextCollectionView
      let previousCollection = self.mainView.previousCollectionView

      let nextBottomInset = nextCollection.adjustedContentInset.bottom
      let previousBottomInset = previousCollection.adjustedContentInset.bottom

      let nextHeight = nextCollection.bounds.height
      let previousHeight = previousCollection.bounds.height

      let nextContentHeight = nextCollection.contentSize.height
      let previousContentHeight = previousCollection.contentSize.height

      let offsetY = scrollView.contentOffset.y

      let nextMaxHeight = max(nextContentHeight, nextHeight)
      let prevoiusMaxHeight = max(previousContentHeight, previousHeight)
      
      let nextMinHeight = min(nextContentHeight, nextHeight)
      let previousMinHeight = min(previousContentHeight, previousHeight)

      let nextMaxOffsetY = nextMaxHeight - nextMinHeight + nextBottomInset
      let previousMaxOffsetY = prevoiusMaxHeight - previousMinHeight + previousBottomInset

      nextCollection.contentOffset = CGPoint(
        x: CGFloat.zero,
        y: min(offsetY, nextMaxOffsetY)
      )
      previousCollection.contentOffset = CGPoint(
        x: CGFloat.zero,
        y: min(offsetY, previousMaxOffsetY)
      )
    }
  }
}
