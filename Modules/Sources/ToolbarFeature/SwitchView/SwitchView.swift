import UIKit
import Core

protocol SwitchViewDelegate: AnyObject {
  func switchView(_ switchView: SwitchView, didSwitchedTo index: Int)
}

final class SwitchView: UIView {
  
  weak var delegate: SwitchViewDelegate?
  
  private lazy var backgroundView: UIView = {
    let effect = UIBlurEffect(style: .light)
    let view = UIVisualEffectView(effect: effect)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.alpha = 0.3
    return view
  }()
  
  private lazy var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    return stackView
  }()
  
  var selectionIndex: Int = 0 {
    didSet {
      updateSelection()
    }
  }
  
  // MARK: - Init
  init() {
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  // MARK: - Setup view
  
  override var intrinsicContentSize: CGSize {
    .init(width: UIView.noIntrinsicMetric, height: 34)
  }
  
  private func setup() {
    accessibilityTraits = .button
    
    layer.cornerRadius = 17
    layer.masksToBounds = true
    
    addSubview(backgroundView)
    
    addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
    ])
  }
  
  // MARK: - Configure
  func configure(with viewModel: ViewModel) {
    stackView.arrangedSubviews.forEach {
      stackView.removeArrangedSubview($0)
    }
    
    viewModel.items.enumerated().forEach { index, item in
      let button = UIButton()
      button.setTitle(item.title, for: .normal)
      button.titleLabel?.textColor = .fromPalette(.text)
      button.layer.cornerRadius = 16
      button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
      button.tag = index
      stackView.addArrangedSubview(button)
    }
    
    updateSelection()
  }
  
  private func updateSelection() {
    stackView.arrangedSubviews.forEach {
      $0.backgroundColor = .clear
    }
    let selectedButton = stackView.arrangedSubviews[selectionIndex]
    selectedButton.backgroundColor = UIColor.white.withAlphaComponent(0.3)
  }
  
  @objc private func buttonAction(_ sender: UIButton) {
    selectionIndex = sender.tag
    delegate?.switchView(self, didSwitchedTo: selectionIndex)
  }
  
}


// MARK: - ViewModel
extension SwitchView {
  struct ViewModel {
    let items: [Item]
    
    struct Item {
      let title: String
    }
  }
}
