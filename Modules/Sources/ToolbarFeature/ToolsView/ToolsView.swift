import UIKit
import Core

protocol ToolsViewDelegate: AnyObject {
  func toolsView(_ toolsView: ToolsView, didTapItemAt index: Int)
}

final class ToolsView: UIView {
  
  enum Selection: Equatable {
    case selected(Int)
    case picked(Int)
  }
  
  weak var delegate: ToolsViewDelegate?
  
  var selection: Selection? {
    willSet {
      if newValue != selection,
      let selection = newValue {
        switch selection {
        case .picked(let index):
          performPick(at: index)
        case .selected(let index):
          performSelection(at: index)
        }
      }
    }
  }
  
  private lazy var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    return stackView
  }()
  
  private lazy var maskLayer: CAGradientLayer = {
    let layer = CAGradientLayer()
    let backgroundColor = UIColor.fromPalette(.background) ?? .black
    layer.colors = [
      backgroundColor.cgColor,
      backgroundColor.withAlphaComponent(0).cgColor
    ]
    layer.locations = [0.9, 1]
    return layer
  }()
  
  private var isDeviceCompact: Bool {
    UIScreen.main.bounds.width <= 320
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
  private func setup() {
    clipsToBounds = true
    
    addSubview(stackView)
    
    let stackHeight: CGFloat = isDeviceCompact ? 60 : 70
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.heightAnchor.constraint(equalToConstant: stackHeight),
    ])
    
    layer.mask = maskLayer
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    maskLayer.frame = bounds
  }
  
  // MARK: - Configure
  
  func configure(with viewModel: ViewModel) {
    stackView.arrangedSubviews.forEach {
      stackView.removeArrangedSubview($0)
    }
    
    viewModel.items.enumerated().forEach { index, item in
      let itemView = ToolBarItemView(item, onTap: { [weak self] in
        guard let self = self else {
          return
        }
        self.delegate?.toolsView(self, didTapItemAt: index)
      })
      
      let itemWidth: CGFloat = isDeviceCompact ? 30 : 40
      stackView.addArrangedSubview(itemView)
      itemView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        itemView.widthAnchor.constraint(equalToConstant: itemWidth)
      ])
      itemView.transform = .init(translationX: 0, y: 100)
      itemView.alpha = 0.5
      
      let appearDelay = 0.5 + 0.03 * CGFloat(index)
      UIView.animate(withDuration: 0.4, delay: appearDelay, usingSpringWithDamping: 0.8, initialSpringVelocity: 1) {
        itemView.transform = .identity
        itemView.alpha = 1
      }
    }
  }
  
  func update(item: ToolBarItemViewModel, at index: Int) {
    let itemView = stackView.arrangedSubviews[index] as? ToolBarItemView
    itemView?.update(with: item)
  }
  
    // MARK: - Private
  
  private func performSelection(at index: Int) {
    let view = stackView.arrangedSubviews[index]
    
    let animationDuration: TimeInterval = 0.2
    let selectedOffset: CGFloat = isDeviceCompact ? 5 : 10
    let scaleFactor: CGFloat = 1.05
    
    UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut]) {
      self.stackView.arrangedSubviews.forEach {
        $0.transform = .identity
      }
      view.transform = .init(translationX: 0, y: -selectedOffset)
        .scaledBy(x: scaleFactor, y: scaleFactor)
    }
  }
  
  private func performPick(at index: Int) {
    let view = stackView.arrangedSubviews[index]
    let stackWidth = stackView.frame.width
    let scaleFactor: CGFloat = 2
    let pickedOffset: CGFloat = isDeviceCompact ? 10 : 20
    let animationDuration: TimeInterval = 0.2
    
    view.layer.anchorPoint = .init(x: 0.5, y: 0.5)
    
    UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut]) {
      self.stackView.arrangedSubviews.enumerated().forEach { viewIndex, view in
        if viewIndex > index {
          view.transform = .init(translationX: 50, y: 100)
            .rotated(by: .pi / 3)
        } else if viewIndex < index {
          view.transform = .init(translationX: -50, y: 100)
            .rotated(by: -.pi / 3)
        }
      }
      let moveX = -(view.frame.midX - stackWidth / 2)
      view.transform = .init(translationX: moveX, y: -pickedOffset)
        .scaledBy(x: scaleFactor, y: scaleFactor)
    }
  }
  
}


// MARK: - ViewModel
extension ToolsView {
  
  struct ViewModel {
    init(items: [ToolBarItemViewModel]) {
      self.items = items
    }    
    let items: [ToolBarItemViewModel]
  }
}
