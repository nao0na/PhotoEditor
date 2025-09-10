import UIKit

final class BlurButton: UIControl {
  
  var image: UIImage? {
    get {
      imageView.image
    }
    set {
      imageView.image = newValue
    }
  }
  
  override var tintColor: UIColor? {
    didSet {
      imageView.tintColor = tintColor
    }
  }
  
  private lazy var backgroundView: UIView = {
    let effect = UIBlurEffect(style: .light)
    let view = UIVisualEffectView(effect: effect)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return view
  }()
  
  private lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return imageView
  }()
  
  init() {
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    addSubview(backgroundView)
    addSubview(imageView)
    
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction)))
  }
    
  override func layoutSubviews() {
    super.layoutSubviews()
    sendSubviewToBack(backgroundView)
  }
  
  @objc private func tapAction() {
    sendActions(for: .touchUpInside)
  }
}
