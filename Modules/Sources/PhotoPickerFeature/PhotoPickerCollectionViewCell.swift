import UIKit

final class PhotoPickerCollectionViewCell: UICollectionViewCell {
  // MARK: - Subviews

  private(set) lazy var imageView: UIImageView = .init(
    frame: .zero
  ).apply {
    $0.contentMode = .scaleAspectFill
  }

  // MARK: - Properties

  private var assetItem: AssetItem?
  private var targetImageSize: CGSize = .zero

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

    imageView.frame = contentView.bounds
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    assetItem = nil
    imageView.image = nil
    targetImageSize = .zero
  }

  // MARK: - Public methods

  func configure(
    with item: AssetItem,
    targetSize: CGSize
  ) {
    if targetImageSize.width >= targetSize.width,
       let _ = imageView.image,
       let asset = assetItem,
       asset.asset == item.asset
    {
      return
    }

    assetItem = item
    targetImageSize = targetSize

    let image = item.fetchThumb(
      for: targetImageSize
    ) { [weak self] image in
      guard let self = self,
            let currentItem = self.assetItem,
            currentItem === item
      else { return }

      self.imageView.image = image
    }

    imageView.image = image
  }

  // MARK: - Private methods

  private func setup() {
    contentView.clipsToBounds = true
    contentView.backgroundColor = .darkGray
    contentView.addSubview(imageView)
  }
}

// MARK: - Identifier

extension PhotoPickerCollectionViewCell {
  static var identifier: String {
    return String(describing: Self.self)
  }
}
