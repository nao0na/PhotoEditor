import UIKit
import Lottie

final class ToolbarView: UIView {
  private(set) lazy var toolsView = ToolsView()
  private(set) lazy var switchView = SwitchView()
  private(set) lazy var adjustView = AdjustView()
  private(set) lazy var backButton = BackButton()
  private(set) lazy var variantsButton = VariantsButton()
  private lazy var shadowView = ShadowView()
  
  private(set) lazy var downloadButton:  UIButton = {
    let button = UIButton()
    let image = UIImage(named: "download", in: .module, with: nil)?.withRenderingMode(.alwaysTemplate)
    button.setImage(image, for: .normal)
    button.tintColor = .fromPalette(.text)
    return button
  }()
  
  private(set) lazy var colorPickerButton = ColorPickerButton()
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup view
  private func setup() {
    toolsView.isHidden = true
    adjustView.isHidden = true
        
    adjustView.isHidden = true
    
    addSubview(shadowView)
    shadowView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      shadowView.leftAnchor.constraint(equalTo: leftAnchor),
      shadowView.rightAnchor.constraint(equalTo: rightAnchor),
      shadowView.bottomAnchor.constraint(equalTo: bottomAnchor),
      shadowView.heightAnchor.constraint(equalToConstant: 150),
    ])
    
    addSubview(toolsView)
    toolsView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      toolsView.leftAnchor.constraint(equalTo: leftAnchor, constant: 60),
      toolsView.rightAnchor.constraint(equalTo: rightAnchor, constant: -60),
      toolsView.heightAnchor.constraint(equalToConstant: 110)
    ])
    
    addSubview(switchView)
    switchView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      switchView.leftAnchor.constraint(equalTo: leftAnchor, constant: 60),
      switchView.rightAnchor.constraint(equalTo: rightAnchor, constant: -60),
      switchView.topAnchor.constraint(equalTo: toolsView.bottomAnchor),
      switchView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8)
    ])
            
    addSubview(backButton)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      backButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
      backButton.centerYAnchor.constraint(equalTo: switchView.centerYAnchor),
      backButton.widthAnchor.constraint(equalToConstant: 34),
      backButton.heightAnchor.constraint(equalToConstant: 34),
    ])

    addSubview(downloadButton)
    downloadButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      downloadButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
      downloadButton.centerYAnchor.constraint(equalTo: switchView.centerYAnchor),
      downloadButton.widthAnchor.constraint(equalToConstant: 34),
      downloadButton.heightAnchor.constraint(equalToConstant: 34),
    ])
    
    addSubview(adjustView)
    adjustView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      adjustView.leftAnchor.constraint(equalTo: leftAnchor, constant: 60),
      adjustView.topAnchor.constraint(equalTo: toolsView.bottomAnchor),
      adjustView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])
    
    addSubview(variantsButton)
    variantsButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      variantsButton.widthAnchor.constraint(equalToConstant: 90),
      variantsButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
      variantsButton.leftAnchor.constraint(equalTo: adjustView.rightAnchor, constant: 12),
      variantsButton.centerYAnchor.constraint(equalTo: switchView.centerYAnchor),
      variantsButton.heightAnchor.constraint(equalToConstant: 34),
    ])
   
    addSubview(colorPickerButton)
    colorPickerButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      colorPickerButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
      colorPickerButton.bottomAnchor.constraint(equalTo: backButton.topAnchor, constant: -16),
      colorPickerButton.widthAnchor.constraint(equalToConstant: 34),
      colorPickerButton.heightAnchor.constraint(equalToConstant: 34),
    ])
    
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let view = super.hitTest(point, with: event)
    if view is ToolsView {
      return nil
    }
    return view
  }
}
