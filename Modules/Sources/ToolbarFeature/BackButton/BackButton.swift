import UIKit
import Lottie
import Core

final class BackButton: UIView {

  var buttonStyle: ButtonStyle = .cancel {
    willSet {
      if newValue != buttonStyle {
        animate(to: newValue)
      }
    }
  }

  private lazy var animationView: AnimationView = {
    let view = AnimationView()
    let animation = Animation.named("backToCancel", bundle: .module)
    view.animation = animation
    view.currentProgress = buttonStyle.toProgress
    return view
  }()
  
  private var tapHandler: (() -> Void)?
  
  // MARK: - Init
  
  init() {
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func animate(to style: ButtonStyle) {
    if UIAccessibility.isReduceMotionEnabled {
      animationView.currentProgress = style.toProgress
    } else {
      animationView.play(
        fromProgress: style.fromProgress,
        toProgress: style.toProgress,
        loopMode: .playOnce
      )
    }
  }
  
  // MARK: - Setup view
  private func setup() {
    addSubview(animationView)
    animationView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
      animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
      animationView.topAnchor.constraint(equalTo: topAnchor),
      animationView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    
    isUserInteractionEnabled = true
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction)))
  }
  
  func configure(with viewModel: ViewModel) {
    tapHandler = viewModel.onTap
  }
  
 
  @objc private func tapAction() {
    tapHandler?()
  }
  
  enum ButtonStyle: Equatable {
    case back
    case cancel
    
    var fromProgress: AnimationProgressTime {
      switch self {
      case .back:
        return 0.5
      case .cancel:
        return 0
      }
    }
    
    var toProgress: AnimationProgressTime {
      switch self {
      case .back:
        return 1
      case .cancel:
        return 0.5
      }
    }
    
    var staticImage: UIImage? {
      switch self {
      case .back:
        return .init(named: "back")
      case .cancel:
        return .init(named: "cancel")
      }
    }
  }
  
  struct ViewModel {
    let onTap: () -> Void
  }
  
}
