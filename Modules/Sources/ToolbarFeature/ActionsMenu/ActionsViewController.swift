import UIKit

final class ActionsViewController: UIViewController {
  
  typealias ActionHandler = () -> Void
  
  struct Action {
    let title: String
    let image: UIImage?
    let handler: ActionHandler
  }
  
  private let actions: [Action]
  private let sourceView: UIView
  
  private lazy var effectView: UIView = {
    let effect = UIBlurEffect(style: .dark)
    let view = UIVisualEffectView(effect: effect)
    return view
  }()
  
  private lazy var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    return stackView
  }()
  
  // MARK: - Init
  init(actions: [Action], sourceView: UIView) {
    self.actions = actions
    self.sourceView = sourceView
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .custom
    transitioningDelegate = self
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
    
  private func setup() {
    view.addSubview(effectView)
    effectView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      effectView.leftAnchor.constraint(equalTo: view.leftAnchor),
      effectView.rightAnchor.constraint(equalTo: view.rightAnchor),
      effectView.topAnchor.constraint(equalTo: view.topAnchor),
      effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    
    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
      stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
      stackView.topAnchor.constraint(equalTo: view.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    
    stackView.arrangedSubviews.forEach {
      $0.removeFromSuperview()
    }
    actions.enumerated().forEach { index, action in
      stackView.addArrangedSubview(ActionView(
        title: action.title,
        image: action.image,
        handler: { [weak self] in
          self?.dismiss(animated: true)
          action.handler()
        }
      ))
      if index < actions.count - 1 {
        stackView.addArrangedSubview(buildSeparator())
      }
    }
  }
  
  private func buildSeparator() -> UIView {
    let view = UIView()
    view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
    NSLayoutConstraint.activate([
      view.heightAnchor.constraint(equalToConstant: 0.33)
    ])
    return view
  }
  
  override var preferredContentSize: CGSize {
    get {
      view.systemLayoutSizeFitting(.init(width: 180, height: UIView.noIntrinsicMetric))
    }
    set {
      super.preferredContentSize = newValue
    }
  }
  
}


// MARK: - ActionsViewControllertrue
extension ActionsViewController {
  final class ActionView: UIView {
    
    private(set) lazy var titleLabel: UILabel = {
      let label = UILabel()
      label.numberOfLines = 1
      return label
    }()
    
    private(set) lazy var imageVew: UIImageView = {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      return imageView
    }()
    
    private var actionHandler: ActionHandler?
    
    init(title: String?, image: UIImage?, handler: ActionHandler?) {
      super.init(frame: .zero)
      setup()
      titleLabel.text = title
      imageVew.image = image
      actionHandler = handler
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
      accessibilityLabel = titleLabel.text
      accessibilityValue = titleLabel.text
      accessibilityTraits = .button
      
      addSubview(titleLabel)
      titleLabel.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      ])
      
      addSubview(imageVew)
      imageVew.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        imageVew.widthAnchor.constraint(equalToConstant: 24),
        imageVew.heightAnchor.constraint(equalToConstant: 24),
        imageVew.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
        imageVew.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      ])
      
      addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction)))
    }
    
    @objc private func tapAction() {
      actionHandler?()
    }
    
  }
}


// MARK: - UIViewControllerTransitioningDelegate
extension ActionsViewController: UIViewControllerTransitioningDelegate {
  public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    ActionsPresentAnimator(sourceView: sourceView)
  }
  
  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    ActionsDismissAnimator(targetView: sourceView)
  }
}
