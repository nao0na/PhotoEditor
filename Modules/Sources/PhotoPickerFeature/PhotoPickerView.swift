import Core
import UIKit
import Photos
import CoreFoundation

final class PhotoPickerView: UIView {
  // MARK: - Subviews

  private lazy var maskLayer: CAGradientLayer = .init().apply {
    let clearColor = UIColor.clear.cgColor
    let blackColor = UIColor.black.cgColor

    $0.colors = [blackColor, blackColor, clearColor]
    $0.locations = [0, 0.2, 1]
  }

  private(set) lazy var blurView: UIVisualEffectView = .init(
    effect: UIBlurEffect(style: .regular)
  ).apply {
    $0.alpha = 0
    $0.layer.mask = maskLayer
  }

  private(set) lazy var collectionView = createCollectionView(
    with: columnsCount
  )

  private(set) lazy var nextCollectionView = createCollectionView(
    with: nextColumnsCount
  )

  private(set) lazy var previousCollectionView = createCollectionView(
    with: previousColumnsCount
  )

  private var snapshotView: UIView? = nil
  private var nextSnapshotView: UIView? = nil
  private var previousSnapshotView: UIView? = nil

  // MARK: - Properties

  var imageTargetSize: CGSize {
    let paddings = CGFloat(columnsCount) - 1
    let width = UIScreen.main.bounds.width
    let scale = UIScreen.main.scale
    let dimension = width / CGFloat(columnsCount) * scale - paddings
    
    return CGSize(width: dimension, height: dimension)
  }

  private var isUpdate: Bool = false
  private var columnsCount: Int = 3

  private var nextColumnsCount: Int {
    if columnsCount == 13 {
      return columnsCount
    }

    return columnsCount + 2
  }

  private var previousColumnsCount: Int {
    if columnsCount == 1 {
      return columnsCount
    }

    return columnsCount - 2
  }

  private var firstScaleFactor: CGFloat = 1
  private var lastScaleFactor: CGFloat = 1

  // MARK: - init/deinit

  override init(frame: CGRect) {
    super.init(frame: frame)

    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - View lifecycle

  override func layoutSubviews() {
    super.layoutSubviews()

    blurView.frame = CGRect(
      x: safeAreaLayoutGuide.layoutFrame.minX,
      y: 0,
      width: safeAreaLayoutGuide.layoutFrame.width,
      height: safeAreaLayoutGuide.layoutFrame.minY + 44
    )
    maskLayer.frame = blurView.bounds

    collectionView.frame = bounds
    nextCollectionView.frame = bounds
    previousCollectionView.frame = bounds
  }

  // MARK: - Private methods

  private func setup() {
    backgroundColor = .black

    addSubview(collectionView)

    insertSubview(blurView, aboveSubview: collectionView)
    insertSubview(nextCollectionView, belowSubview: collectionView)
    insertSubview(previousCollectionView, belowSubview: collectionView)

    let pinchGesture = UIPinchGestureRecognizer(
      target: self,
      action: #selector(PhotoPickerView.pinchGestureRecognizer(sender:))
    )
    collectionView.addGestureRecognizer(pinchGesture)
  }

  private func createCollectionView(
    with columns: Int
  ) -> UICollectionView {
    let layout = compositionalLayout(
      columns: columns
    )

    let collectionView = UICollectionView(
      frame: CGRect.zero,
      collectionViewLayout: layout
    )

    collectionView.backgroundColor = UIColor.black
    collectionView.alwaysBounceVertical = true
    collectionView.alwaysBounceHorizontal = false
    collectionView.showsVerticalScrollIndicator = true
    collectionView.showsHorizontalScrollIndicator = false

    return collectionView
  }

  @objc private func pinchGestureRecognizer(
    sender: UIPinchGestureRecognizer
  ) {
    guard let _ = sender.view
    else { return }

    switch sender.state {
    case .began:
      if isUpdate == true {
        sender.state = .failed
        return
      }

      let isZoomOut = isZoomOut(scale: sender.scale)

      if isZoomOut == true, columnsCount == nextColumnsCount {
        collectionViewZoomOutCanceled(sender)
        return
      }

      if isZoomOut == false, columnsCount == previousColumnsCount {
        collectionViewZoomInCanceled(sender)
        return
      }

      collectionViewZoomStartChange(sender)
    case .changed:
      let scale = sender.scale
      let isZoomOut = isZoomOut(scale: scale)
      let progress = progress(for: scale, isZoomOut: isZoomOut)

      if isZoomOut == true, progress >= 1 {
        collectionViewZoomOutFinish(sender)
        return
      }

      if isZoomOut == false, progress >= 1 {
        collectionViewZoomInFinish(sender)
        return
      }

      if isZoomOut == true, scale > lastScaleFactor {
        collectionViewZoomOutCanceled(sender)
        return
      }

      if isZoomOut == false, scale < lastScaleFactor {
        collectionViewZoomInCanceled(sender)
        return
      }

      isZoomOut
        ? collectionViewZoomOutDidChanged(sender)
        : collectionViewZoomInDidChanged(sender)
    case .cancelled:
      let scale = firstScaleFactor
      let isZoomOut = isZoomOut(scale: scale)

      isZoomOut
        ? collectionViewZoomOutCanceled(sender)
        : collectionViewZoomInCanceled(sender)
    case .ended:
      let scale = firstScaleFactor
      let isZoomOut = isZoomOut(scale: scale)

      isZoomOut
        ? collectionViewZoomOutFinish(sender)
        : collectionViewZoomInFinish(sender)
    default:
      break
    }
  }

  private func isZoomOut(scale: CGFloat) -> Bool {
    return scale < 1
  }

  private func progress(for scale: CGFloat, isZoomOut: Bool) -> CGFloat {
    if isZoomOut == true {
      return scale * -2 + 2
    }

    return scale - 1
  }
}

// MARK: - Handle pinch gesture

private extension PhotoPickerView {

  // MARK: - Start

  private func collectionViewZoomStartChange(_ sender: UIPinchGestureRecognizer) {
    isUpdate = true

    firstScaleFactor = sender.scale
    lastScaleFactor = sender.scale

    collectionView.showsVerticalScrollIndicator = false
    nextCollectionView.showsVerticalScrollIndicator = false
    previousCollectionView.showsVerticalScrollIndicator = false
  }

  // MARK: - Changed

  private func collectionViewZoomOutDidChanged(_ sender: UIPinchGestureRecognizer) {
    let scale = sender.scale

    guard firstScaleFactor < 1, scale < 1
    else { return }

    addSnapshotIfNeededForZoomOut()

    lastScaleFactor = scale

    collectionView.alpha = 0
    nextCollectionView.alpha = 0
    previousCollectionView.alpha = 0

    snapshotView?.layer.anchorPoint = .zero
    nextSnapshotView?.layer.anchorPoint = .zero

    let progress = progress(for: scale, isZoomOut: true)

    let snapshotScale = CGFloat(columnsCount) / CGFloat(nextColumnsCount)
    let nextSnapshotScale = CGFloat(nextColumnsCount) / CGFloat(columnsCount)

    let targetSnapshotScale = interpolate(
      from: 1,
      to: snapshotScale,
      progress: progress
    )
    let targetNextSnapshotScale = interpolate(
      from: nextSnapshotScale,
      to: 1,
      progress: progress
    )

    let yOffset = collectionView.adjustedContentInset.top - (
      collectionView.adjustedContentInset.top * targetSnapshotScale
    )

    let nextYOffset = nextCollectionView.adjustedContentInset.top - (
      nextCollectionView.adjustedContentInset.top * targetNextSnapshotScale
    )

    snapshotView?.transform = .init(
      translationX: 0,
      y: yOffset
    ).scaledBy(
      x: targetSnapshotScale,
      y: targetSnapshotScale
    )
    
    nextSnapshotView?.transform = .init(
      translationX: 0,
      y: nextYOffset
    ).scaledBy(
      x: targetNextSnapshotScale,
      y: targetNextSnapshotScale
    )

    let snapshotAlpha = interpolate(
      from: 1,
      to: 0,
      progress: progress
    )

    snapshotView?.alpha = snapshotAlpha
  }

  private func collectionViewZoomInDidChanged(_ sender: UIPinchGestureRecognizer) {
    let scale = sender.scale

    guard firstScaleFactor > 1, scale > 1
    else { return }

    addSnapshotIfNeededForZoomIn()

    lastScaleFactor = scale

    collectionView.alpha = 0
    nextCollectionView.alpha = 0
    previousCollectionView.alpha = 0

    snapshotView?.layer.anchorPoint = .zero
    previousSnapshotView?.layer.anchorPoint = .zero

    let progress = progress(for: scale, isZoomOut: false)

    let snapshotScale = CGFloat(columnsCount) / CGFloat(previousColumnsCount)
    let previousSnapshotScale = CGFloat(previousColumnsCount) / CGFloat(columnsCount)

    let targetSnapshotScale = interpolate(
      from: 1,
      to: snapshotScale,
      progress: progress
    )
    let previousNextSnapshotScale = interpolate(
      from: previousSnapshotScale,
      to: 1,
      progress: progress
    )

    let yOffset = collectionView.adjustedContentInset.top - (
      collectionView.adjustedContentInset.top * targetSnapshotScale
    )

    let previousYOffset = nextCollectionView.adjustedContentInset.top - (
      nextCollectionView.adjustedContentInset.top * previousNextSnapshotScale
    )

    snapshotView?.transform = .init(
      translationX: 0,
      y: yOffset
    ).scaledBy(
      x: targetSnapshotScale,
      y: targetSnapshotScale
    )
    
    previousSnapshotView?.transform = .init(
      translationX: 0,
      y: previousYOffset
    ).scaledBy(
      x: previousNextSnapshotScale,
      y: previousNextSnapshotScale
    )

    let snapshotAlpha = interpolate(
      from: 1,
      to: 0,
      progress: progress
    )

    snapshotView?.alpha = snapshotAlpha
  }

  // MARK: - Canceled

  private func collectionViewZoomOutCanceled(_ sender: UIPinchGestureRecognizer) {
    if sender.state != .cancelled {
      sender.state = .cancelled
      return
    }

    guard sender.state == .cancelled
    else { return }

    UIView.animate(
      withDuration: 0.25,
      animations: {
        self.snapshotView?.transform = .identity
        self.snapshotView?.alpha = 1

        let nextSnapshotScale = CGFloat(self.nextColumnsCount) / CGFloat(self.columnsCount)
        let nextYOffset = self.nextCollectionView.adjustedContentInset.top - (
          self.nextCollectionView.adjustedContentInset.top * nextSnapshotScale
        )

        self.nextSnapshotView?.transform = .init(
          translationX: 0,
          y: nextYOffset
        ).scaledBy(
          x: nextSnapshotScale,
          y: nextSnapshotScale
        )

        self.nextSnapshotView?.alpha = 0
      },
      completion: { _ in
        self.firstScaleFactor = 1
        self.lastScaleFactor = 1

        self.snapshotView?.removeFromSuperview()
        self.snapshotView = nil

        self.nextSnapshotView?.removeFromSuperview()
        self.nextSnapshotView = nil

        self.collectionView.alpha = 1
        self.nextCollectionView.alpha = 1
        self.previousCollectionView.alpha = 1

        self.collectionView.showsVerticalScrollIndicator = true
        self.nextCollectionView.showsVerticalScrollIndicator = true
        self.previousCollectionView.showsVerticalScrollIndicator = true

        self.isUpdate = false
      }
    )
  }

  private func collectionViewZoomInCanceled(_ sender: UIPinchGestureRecognizer) {
    if sender.state != .cancelled {
      sender.state = .cancelled
      return
    }

    guard sender.state == .cancelled
    else { return }

    UIView.animate(
      withDuration: 0.25,
      animations: {
        self.snapshotView?.transform = .identity
        self.snapshotView?.alpha = 1

        let previousSnapshotScale = CGFloat(self.previousColumnsCount) / CGFloat(self.columnsCount)
        let nextYOffset = self.previousCollectionView.adjustedContentInset.top - (
          self.previousCollectionView.adjustedContentInset.top * previousSnapshotScale
        )

        self.previousSnapshotView?.transform = .init(
          translationX: 0,
          y: nextYOffset
        ).scaledBy(
          x: previousSnapshotScale,
          y: previousSnapshotScale
        )

        self.previousSnapshotView?.alpha = 0
      },
      completion: { _ in
        self.firstScaleFactor = 1
        self.lastScaleFactor = 1

        self.snapshotView?.removeFromSuperview()
        self.snapshotView = nil

        self.previousSnapshotView?.removeFromSuperview()
        self.previousSnapshotView = nil

        self.collectionView.alpha = 1
        self.nextCollectionView.alpha = 1
        self.previousCollectionView.alpha = 1

        self.collectionView.showsVerticalScrollIndicator = true
        self.nextCollectionView.showsVerticalScrollIndicator = true
        self.previousCollectionView.showsVerticalScrollIndicator = true

        self.isUpdate = false
      }
    )
  }


  // MARK: - Finish

  private func collectionViewZoomOutFinish(_ sender: UIPinchGestureRecognizer) {
    if sender.state != .ended {
      sender.state = .ended
      return
    }

    guard sender.state == .ended
    else { return }

    UIView.animate(
      withDuration: 0.35,
      animations: {
        let snapshotScale = CGFloat(self.columnsCount) / CGFloat(self.nextColumnsCount)
        let yOffset = self.collectionView.adjustedContentInset.top - (
          self.collectionView.adjustedContentInset.top * snapshotScale
        )

        self.snapshotView?.transform = .init(
          translationX: 0,
          y: yOffset
        ).scaledBy(
          x: snapshotScale,
          y: snapshotScale
        )
        self.snapshotView?.alpha = 0

        self.nextSnapshotView?.alpha = 1
        self.nextSnapshotView?.transform = .identity
      },
      completion: { _ in
        self.firstScaleFactor = 1
        self.lastScaleFactor = 1

        self.columnsCount += 2

        let layout = compositionalLayout(columns: self.columnsCount)
        let nextLayout = compositionalLayout(columns: self.nextColumnsCount)
        let previousLayout = compositionalLayout(columns: self.previousColumnsCount)

        self.collectionView.setCollectionViewLayout(layout, animated: false)
        self.collectionView.contentOffset = self.nextCollectionView.contentOffset

        self.snapshotView?.removeFromSuperview()
        self.snapshotView = nil

        self.nextSnapshotView?.removeFromSuperview()
        self.nextSnapshotView = nil

        self.collectionView.alpha = 1
        self.nextCollectionView.alpha = 1
        self.previousCollectionView.alpha = 1

        self.collectionView.showsVerticalScrollIndicator = true
        self.nextCollectionView.showsVerticalScrollIndicator = true
        self.previousCollectionView.showsVerticalScrollIndicator = true

        CFRunLoopPerformBlock(
          CFRunLoopGetMain(),
          CFRunLoopMode.defaultMode.rawValue
        ) {
          self.collectionView.reloadData()
          self.nextCollectionView.setCollectionViewLayout(
            nextLayout,
            animated: false
          )
          self.previousCollectionView.setCollectionViewLayout(
            previousLayout,
            animated: false
          )
          self.isUpdate = false
        }
      }
    )
  }

  private func collectionViewZoomInFinish(_ sender: UIPinchGestureRecognizer) {
    if sender.state != .ended {
      sender.state = .ended
      return
    }

    guard sender.state == .ended
    else { return }

    UIView.animate(
      withDuration: 0.35,
      animations: {
        let snapshotScale = CGFloat(self.columnsCount) / CGFloat(self.previousColumnsCount)
        let yOffset = self.collectionView.adjustedContentInset.top - (
          self.collectionView.adjustedContentInset.top * snapshotScale
        )

        self.snapshotView?.transform = .init(
          translationX: 0,
          y: yOffset
        ).scaledBy(
          x: snapshotScale,
          y: snapshotScale
        )
        self.snapshotView?.alpha = 0

        self.previousSnapshotView?.alpha = 1
        self.previousSnapshotView?.transform = .identity
      },
      completion: { _ in
        self.firstScaleFactor = 1
        self.lastScaleFactor = 1

        self.columnsCount -= 2

        let layout = compositionalLayout(columns: self.columnsCount)
        let nextLayout = compositionalLayout(columns: self.nextColumnsCount)
        let previousLayout = compositionalLayout(columns: self.previousColumnsCount)

        self.collectionView.setCollectionViewLayout(layout, animated: false)
        self.collectionView.contentOffset = self.previousCollectionView.contentOffset

        self.snapshotView?.removeFromSuperview()
        self.snapshotView = nil

        self.previousSnapshotView?.removeFromSuperview()
        self.previousSnapshotView = nil

        self.collectionView.alpha = 1
        self.nextCollectionView.alpha = 1
        self.previousCollectionView.alpha = 1

        self.collectionView.showsVerticalScrollIndicator = true
        self.nextCollectionView.showsVerticalScrollIndicator = true
        self.previousCollectionView.showsVerticalScrollIndicator = true

        CFRunLoopPerformBlock(
          CFRunLoopGetMain(),
          CFRunLoopMode.defaultMode.rawValue
        ) {
          self.collectionView.reloadData()
          self.nextCollectionView.setCollectionViewLayout(
            nextLayout,
            animated: false
          )
          self.previousCollectionView.setCollectionViewLayout(
            previousLayout,
            animated: false
          )
          self.isUpdate = false
        }
      }
    )
  }

  // MARK: - Snapshot

  private func addSnapshotIfNeededForZoomOut() {
    guard snapshotView == nil,
          nextSnapshotView == nil
    else { return }

    guard let view = collectionView.snapshotView(afterScreenUpdates: false),
          let nextView = nextCollectionView.snapshotView(afterScreenUpdates: false)
    else { return }

    view.layer.anchorPoint = .zero
    view.frame = bounds
    view.alpha = 1

    nextView.layer.anchorPoint = .zero
    nextView.frame = bounds
    nextView.alpha = 1

    let nextSnapshotScale = CGFloat(nextColumnsCount) / CGFloat(columnsCount)
    let nextYOffset = nextCollectionView.adjustedContentInset.top - (
      nextCollectionView.adjustedContentInset.top * nextSnapshotScale
    )

    nextView.transform = .init(
      translationX: 0,
      y: nextYOffset
    ).scaledBy(
      x: nextSnapshotScale,
      y: nextSnapshotScale
    )
    
    insertSubview(nextView, aboveSubview: collectionView)
    insertSubview(view, aboveSubview: nextView)

    snapshotView = view
    nextSnapshotView = nextView
  }

  private func addSnapshotIfNeededForZoomIn() {
    guard snapshotView == nil,
          previousSnapshotView == nil
    else { return }

    guard let view = collectionView.snapshotView(afterScreenUpdates: false),
          let previousView = previousCollectionView.snapshotView(afterScreenUpdates: false)
    else { return }

    view.layer.anchorPoint = .zero
    view.frame = bounds
    view.alpha = 1

    previousView.layer.anchorPoint = .zero
    previousView.frame = bounds
    previousView.alpha = 1

    let previousSnapshotScale = CGFloat(columnsCount) / CGFloat(previousColumnsCount)
    let previousYOffset = previousCollectionView.adjustedContentInset.top - (
      previousCollectionView.adjustedContentInset.top * previousSnapshotScale
    )

    previousView.transform = .init(
      translationX: 0,
      y: previousYOffset
    ).scaledBy(
      x: previousSnapshotScale,
      y: previousSnapshotScale
    )
    
    insertSubview(previousView, aboveSubview: collectionView)
    insertSubview(view, aboveSubview: previousView)

    snapshotView = view
    previousSnapshotView = previousView
  }
}

// MARK: - UICollectionViewCompositionalLayout

private func compositionalLayout(
  columns: Int
) -> UICollectionViewLayout {
  return UICollectionViewCompositionalLayout { section, environment in
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .fractionalHeight(1)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .fractionalWidth(1 / CGFloat(columns))
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitem: item,
      count: columns
    )
    group.interItemSpacing = .fixed(1)
    
    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = 1
    return section
  }
}
