import UIKit

final class ShadowView: UIView {
  
  private lazy var maskLayer: CAGradientLayer = {
    let layer = CAGradientLayer()
    let backgroundColor = UIColor.fromPalette(.background) ?? .black
    layer.colors = [
      backgroundColor.withAlphaComponent(0).cgColor,
      backgroundColor.cgColor
    ]
    layer.locations = [0, 0.5]
    return layer
  }()
  
  private lazy var effectView: UIVisualEffectView = {
    let effect = UIBlurEffect(style: .dark)
    let view = UIVisualEffectView(effect: effect)
    return view
  }()
  
  
  // MARK: - Init
  
  init() {
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup view
  private func setup() {
    effectView.layer.mask = maskLayer
    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(effectView)
  }

  
  // MARK: - Layout
  override func layoutSubviews() {
    super.layoutSubviews()
    maskLayer.frame = bounds
  }
  
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    false
  }
}
