import UIKit
import Core

protocol AdjustViewDelegate: AnyObject {
  func adjustViewValueDidChanged(_ view: AdjustView)
}

final class AdjustView: UIView {

  weak var delegate: AdjustViewDelegate?
  
  func showAnimated(_ completion: (() -> Void)? = nil) {
    prepareAppear()
    performAppear(completion)
  }
  
  func hideAnimated(_ completion: (() -> Void)? = nil) {
    performDisappear(completion)
  }
  
  private(set) var minValue: CGFloat = 0
  private(set) var maxValue: CGFloat = 0
  private(set) var value: CGFloat = 0 {
    didSet {
      updateHandlePosition()
    }
  }
  
  private var handleSize: CGFloat = 30
    
  private lazy var handleLayer: CAShapeLayer = {
    let layer = CAShapeLayer()
    layer.fillColor = UIColor.fromPalette(.handleColor)?.cgColor
    return layer
  }()
  
  private lazy var trackLayer: CAShapeLayer = {
    let layer = CAShapeLayer()
    layer.fillColor = UIColor.fromPalette(.trackColor)?.cgColor
    return layer
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
    accessibilityTraits = .adjustable
    
    layer.addSublayer(trackLayer)
    layer.addSublayer(handleLayer)
    
    addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureAction)))
  }
  
  // MARK: - Configure
  func configure(with viewModel: ViewModel) {
    handleSize = viewModel.handleSize
    minValue = viewModel.minValue
    maxValue = viewModel.maxValue
    value = viewModel.value
  }
  
  //MARK: - Layout
  override func layoutSubviews() {
    super.layoutSubviews()
    handleLayer.frame = bounds
    trackLayer.frame = bounds
    updateHandlePosition()
    updateTrackPosition()
  }
  
  private var handleRect: CGRect {
    guard maxValue > minValue else {
      return .zero
    }
    let scale = bounds.width / (maxValue - minValue)
    let posX = (value - minValue) * scale
    return CGRect(
      x: min(max(0, posX), bounds.width - handleSize),
      y: (bounds.height - handleSize) / 2,
      width: handleSize,
      height: handleSize
    )
  }
  
  private func updateTrackPosition() {
    let path = CGMutablePath()
    let midY = bounds.midY
    
    path.addArc(
      center: .init(x: 4, y: midY),
      radius: 4,
      startAngle: .pi * 0.5,
      endAngle: .pi * 1.5,
      clockwise: false
    )

    path.addArc(
      center: .init(x: bounds.width - 12, y: midY),
      radius: 12,
      startAngle: .pi * 1.5,
      endAngle: .pi * 0.5,
      clockwise: false
    )

    path.closeSubpath()
    
    trackLayer.path = path
  }
  
  private func updateHandlePosition() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    handleLayer.path = UIBezierPath(roundedRect: handleRect, cornerRadius: handleSize / 2).cgPath
    CATransaction.commit()
  }
  
  
  // MARK: - Animations
  
  private func prepareAppear() {
    let initialRect = CGRect(
      x: 0,
      y: (bounds.height - handleSize) / 2,
      width: bounds.width / 2,
      height: handleSize
    )
    
    handleLayer.path = UIBezierPath(roundedRect: initialRect, cornerRadius: handleSize / 2).cgPath
    
    handleLayer.opacity = 0
    trackLayer.opacity = 0
    
    isHidden = false
  }
  
  private func performAppear(_ completion: (() -> Void)?) {
    guard bounds.width > 0 else {
      return
    }

    let targetPath = UIBezierPath(roundedRect: handleRect, cornerRadius: handleSize / 2).cgPath
            
    if !UIAccessibility.isReduceMotionEnabled {
      let relativeValue = value / (maxValue - minValue)
      let animationDuration: TimeInterval = 0.2 + 0.1 * relativeValue

      let pathAnimation = CABasicAnimation(keyPath: "path")
      pathAnimation.duration = animationDuration
      pathAnimation.timingFunction = .init(name: .easeInEaseOut)
      pathAnimation.fromValue = handleLayer.path
      pathAnimation.toValue = targetPath
      
      let opacityAnimation = CABasicAnimation(keyPath: "opacity")
      opacityAnimation.duration = animationDuration
      opacityAnimation.fromValue = 0
      opacityAnimation.toValue = 1
      
      CATransaction.begin()
      CATransaction.setCompletionBlock {
        completion?()
      }
      handleLayer.path = targetPath
      handleLayer.opacity = 1
      trackLayer.opacity = 1
      
      handleLayer.add(pathAnimation, forKey: nil)
      handleLayer.add(opacityAnimation, forKey: nil)
      trackLayer.add(opacityAnimation, forKey: nil)
      CATransaction.commit()
    } else {
      handleLayer.path = targetPath
      handleLayer.opacity = 1
      trackLayer.opacity = 1
    }
  }
  
  private func performDisappear(_ completion: (() -> Void)?) {
    let finalRect = CGRect(
      x: 0,
      y: (bounds.height - handleSize) / 2,
      width: bounds.width / 2,
      height: handleSize
    )
    
    let targetPath = UIBezierPath(roundedRect: finalRect, cornerRadius: handleSize / 2).cgPath
    
    if !UIAccessibility.isReduceMotionEnabled {
      let relativeValue = value / (maxValue - minValue)
      let animationDuration: TimeInterval = 0.2 + 0.1 * relativeValue

      let pathAnimation = CABasicAnimation(keyPath: "path")
      pathAnimation.duration = animationDuration
      pathAnimation.timingFunction = .init(name: .easeInEaseOut)
      pathAnimation.fromValue = handleLayer.path
      pathAnimation.toValue = targetPath
      
      let opacityAnimation = CABasicAnimation(keyPath: "opacity")
      opacityAnimation.duration = animationDuration
      opacityAnimation.fromValue = 1
      opacityAnimation.toValue = 0
      
      CATransaction.begin()
      CATransaction.setCompletionBlock { [weak self] in
        self?.isHidden = true
        completion?()
      }
      
      handleLayer.path = targetPath
      handleLayer.opacity = 0
      trackLayer.opacity = 0
      
      handleLayer.add(pathAnimation, forKey: nil)
      handleLayer.add(opacityAnimation, forKey: nil)
      trackLayer.add(opacityAnimation, forKey: nil)
      
      CATransaction.commit()
    } else {
      isHidden = true
    }
  }
  
  
  // MARK: - Actions
  
  @objc private func panGestureAction(recognizer: UIPanGestureRecognizer) {
    guard bounds.width > 0 else {
      return
    }
    
    let translation = recognizer.translation(in: self)
    let scale = (maxValue - minValue) / bounds.width
    let diff = translation.x * scale

    recognizer.setTranslation(.zero, in: self)

    value = min(maxValue, max(minValue, value + diff))
    delegate?.adjustViewValueDidChanged(self)
  }
}


// MARK: - ViewModel
extension AdjustView {
  struct ViewModel {
    internal init(minValue: CGFloat, maxValue: CGFloat, value: CGFloat, handleSize: CGFloat = 30) {
      self.minValue = minValue
      self.maxValue = maxValue
      self.value = value
      self.handleSize = handleSize
    }
    
    let minValue: CGFloat
    let maxValue: CGFloat
    let value: CGFloat
    let handleSize: CGFloat
  }
}
