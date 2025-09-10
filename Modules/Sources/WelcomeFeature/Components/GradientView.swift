import Core
import UIKit

final class GradientView: UIView {
  // MARK: - Properties

  private let colors: [CGColor]
  private let startPoint: CGPoint
  private let endPoint: CGPoint

  private lazy var gradientLayer: CAGradientLayer = .init().apply {
    $0.colors = colors
    $0.startPoint = startPoint
    $0.endPoint = endPoint
  }

  // MARK: - init/deinit

  init(
    colors: [UIColor],
    startPoint: CGPoint,
    endPoint: CGPoint,
    frame: CGRect
  ) {
    self.colors = colors.map { $0.cgColor }
    self.startPoint = startPoint
    self.endPoint = endPoint

    super.init(frame: frame)

    layer.addSublayer(gradientLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - View lifecycle

  override func layoutSubviews() {
    super.layoutSubviews()

    gradientLayer.frame = bounds
  }
}
