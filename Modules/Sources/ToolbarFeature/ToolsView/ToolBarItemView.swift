import UIKit
import Core

final class ToolBarItemView: UIView {
    
  private(set) var viewModel: ToolBarItemViewModel
  
  private lazy var baseLayer = CALayer()
  private lazy var tipLayer = CALayer()
  private lazy var tipMaskLayer = CALayer()
  
  private lazy var accentLayer: CALayer = {
    let layer = CALayer()
    layer.mask = accentMaskLayer
    layer.opacity = 0.8
    layer.masksToBounds = true
    layer.cornerRadius = 1
    return layer
  }()
  
  private lazy var accentMaskLayer: CALayer = {
    let layer = CAGradientLayer()
    layer.startPoint = .init(x: 0, y: 0)
    layer.endPoint = .init(x: 1, y: 0)

    layer.colors = [
      UIColor.white.withAlphaComponent(0.3).cgColor,
      UIColor.white.cgColor,
      UIColor.white.withAlphaComponent(0.3).cgColor,
    ]
    return layer
  }()
  
  private var tapHanlder: () -> Void
  
  // MARK: - Init
  
  init(_ viewModel: ToolBarItemViewModel, onTap: @escaping () -> Void) {
    self.viewModel = viewModel
    self.tapHanlder = onTap
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup view
  private func setup() {
    accessibilityTraits = .button
    
    isUserInteractionEnabled = true
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureAction)))
        
    layer.addSublayer(baseLayer)
    baseLayer.contents = viewModel.baseImage?.cgImage
  }
  
  func update(with viewModel: ToolBarItemViewModel) {
    self.viewModel = viewModel
    setNeedsLayout()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    tipMaskLayer.contents = viewModel.tipImage?.cgImage
    baseLayer.contents = viewModel.baseImage?.cgImage
    
    let spacing = bounds.width * viewModel.hSpacing 
    let baseWidth = bounds.width - spacing * 2
    let baseSize = CGSize(
      width: baseWidth,
      height: baseWidth / viewModel.baseSize.width  *  viewModel.baseSize.height
    )
    let baseFrame = CGRect(
      origin: .init(x: spacing, y: 9),
      size: baseSize
    )
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    baseLayer.frame = baseFrame
    tipLayer.frame = baseFrame
    tipMaskLayer.frame = tipLayer.bounds
    
    let accentWidth = baseFrame.width * 0.8
    let accentHeight = 24 * viewModel.strokeSize / viewModel.maxStrokeSize
    accentLayer.frame = CGRect(
      x: baseFrame.minX + (baseFrame.width - accentWidth) / 2,
      y: baseFrame.height * viewModel.accentOffset,
      width: accentWidth,
      height: accentHeight
    )
    accentMaskLayer.frame = accentLayer.bounds
    CATransaction.commit()
    
    viewModel.tipImage.map {
      tipMaskLayer.contents = $0.cgImage
      tipLayer.mask = tipMaskLayer
      tipLayer.backgroundColor = viewModel.color?.cgColor
      layer.addSublayer(tipLayer)
    }
    
    viewModel.color.map {
      accentLayer.backgroundColor = $0.cgColor
      layer.addSublayer(accentLayer)
    }   
  }
  
  @objc private func tapGestureAction() {
    tapHanlder()
  }
}
