import UIKit

final class ColorPickerButton: UIButton {
  
  var pickedColor: UIColor = .white {
    didSet {
      updatePickedColor()
    }
  }
  
  private lazy var backgroundLayer = CALayer()
  private lazy var pickedColorLayer = CALayer()
  
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
    layer.addSublayer(backgroundLayer)
    layer.addSublayer(pickedColorLayer)
  }
  
  // MARK: - Layout
  
  override func layoutSubviews() {
    super.layoutSubviews()
    updateBackground()
    updatePickedColor()
  }
  
  private func updatePickedColor() {
    pickedColorLayer.frame = bounds.insetBy(dx: 7, dy: 7)
    pickedColorLayer.cornerRadius = pickedColorLayer.frame.width / 2
    pickedColorLayer.backgroundColor = pickedColor.cgColor
  }
  
  private func updateBackground() {
    backgroundLayer.frame = bounds
    backgroundLayer.contents = buildGradientImage(bounds.width / 2)
    let mask = CALayer()
    mask.frame = backgroundLayer.bounds
    mask.borderWidth = 3
    mask.borderColor = UIColor.white.cgColor
    mask.cornerRadius = mask.frame.width / 2
    backgroundLayer.mask = mask
  }
  
  private func buildGradientImage(_ radius: CGFloat) -> CGImage? {
    guard radius > 0 else {
      return nil
    }
    
    let screenScale = UIScreen.main.scale
    
    let filter = CIFilter(name: "CIHueSaturationValueGradient", parameters: [
      "inputColorSpace": CGColorSpaceCreateDeviceRGB(),
      "inputDither": 0,
      "inputRadius": radius * screenScale,
      "inputSoftness": 0,
      "inputValue": 1
    ])
    let context = CIContext(options: nil)
    
    if let ciImage = filter?.outputImage,
       let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
      return cgImage
    }
    return nil
  }
  
}


