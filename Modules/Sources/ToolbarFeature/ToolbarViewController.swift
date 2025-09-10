import UIKit

enum BottomItem {
  case switchControl(selectedIndex: Int)
  case adjustControl(min: CGFloat, max: CGFloat, value: CGFloat)
}

enum BackItem {
  case back
  case cancel
}

enum RightItem {
  case download
  case variants(selectedIndex: Int, allVariants: [VariantViewModel])
}

enum CenterItem {
  case toolBar
  case textBar
}

// MARK: - View input
protocol ToolbarViewInput: AnyObject {
  func setCenterItem(_ item: CenterItem)
  func setupToolbar(items: [ToolBarItemViewModel])
  func updateToolbar(item: ToolBarItemViewModel, at index: Int)
  func selectItem(at index: Int)
  func pickItem(at index: Int)
  func setPickedColor(_ color: UIColor)
  func setBottomItem(_ item: BottomItem)
  func setBackItem(_ item: BackItem)
  func setRightItem(_ item: RightItem)
  func setTopControlsVisible(_ visible: Bool)
  func showVariantsPicker(variants: [VariantViewModel])
  func successHapticFeedback()
  func failHapticFeedback()
}

// MARK: - View output
protocol ToolbarViewOutput: AnyObject {
  func onViewDidLoad()
  func onViewDidAppear()
  func onTapTool(at index: Int)
  func onSwitchToDrawing()
  func onAdjust(strokeSize: CGFloat)
  func onBackButtonTapped()
  func onSelectVariant(at index: Int)
  func onTapVariantButton()
  func onTapColorPickerButton()
  func onTapDownloadButton()
}

public final class ToolbarViewController: UIViewController {
  
  private let output: ToolbarViewOutput
  
  // MARK: - Subviews
  
  private lazy var mainView: ToolbarView = .init(
    frame: .zero
  )

  private let feedbackGenerator = UINotificationFeedbackGenerator()
  
  // MARK: - init/deinit
  
  public init(
    initialState: ToolbarState = .default,
    delegate: ToolbarDelegate? = nil
  ) {

    let presenter = ToolbarPresenter(
      initialState: initialState,
      delegate: delegate
    )
    
    self.output = presenter
    super.init(nibName: nil, bundle: nil)
    presenter.view = self
    presenter.router = .init(rootController: self)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - VC lifecycle
    
  public override func loadView() {
    view = mainView
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    mainView.toolsView.delegate = self
    mainView.adjustView.delegate = self
    configureSwitchView()
    configureBackButton()
    configureVariantsButton()
    configureColorPickerButton()
    configureDownloadButton()
    output.onViewDidLoad()
  }
  
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    output.onViewDidAppear()
  }
  
  
  // MARK: - Setup subviews
  
  private func configureDownloadButton() {
    mainView.downloadButton.addTarget(self, action: #selector(downloadButtonAction), for: .touchUpInside)
  }
  
  private func configureVariantsButton() {
    mainView.variantsButton.addTarget(self, action: #selector(variantsButtonAction), for: .touchUpInside)
  }
  
  private func configureSwitchView() {
    mainView.switchView.configure(with: .init(items: [
      .init(title: "Кисти 🖌️"),
    ]))
    mainView.switchView.delegate = self
  }
  
  private func configureBackButton() {
    mainView.backButton.configure(with: .init(onTap: { [weak self] in
      self?.output.onBackButtonTapped()
    }))
  }
  
  private func configureColorPickerButton() {
    mainView.colorPickerButton.addTarget(self, action: #selector(colorPickerAction), for: .touchUpInside)
  }
  
  // MARK: - Actions
  
  @objc private func variantsButtonAction() {
    output.onTapVariantButton()
  }
    
  @objc private func colorPickerAction() {
    output.onTapColorPickerButton()
  }
    
  @objc private func downloadButtonAction() {
    output.onTapDownloadButton()
  }
    
}


// MARK: - ToolbarViewInput
extension ToolbarViewController: ToolbarViewInput {
  
  func successHapticFeedback() {
    feedbackGenerator.notificationOccurred(.success)
  }
  
  func failHapticFeedback() {
    feedbackGenerator.notificationOccurred(.error)
  }
  
  func setCenterItem(_ item: CenterItem) {
    switch item {
    case .toolBar:
      mainView.toolsView.isHidden = false
      mainView.switchView.selectionIndex = 0
    case .textBar:
      mainView.toolsView.isHidden = true
      mainView.switchView.selectionIndex = 1
    }
  }
      
  func selectItem(at index: Int) {
    mainView.toolsView.selection = .selected(index)
  }
  
  func pickItem(at index: Int) {
    mainView.toolsView.selection = .picked(index)
  }
  
  func setupToolbar(items: [ToolBarItemViewModel]) {
    mainView.toolsView.configure(with: .init(
      items: items
    ))
  }
  
  func updateToolbar(item: ToolBarItemViewModel, at index: Int) {
    mainView.toolsView.update(item: item, at: index)
  }
  
  func setPickedColor(_ color: UIColor) {
    mainView.colorPickerButton.pickedColor = color
  }
  
  func setBottomItem(_ item: BottomItem) {
    self.mainView.apply { view in
      switch item {
      case .switchControl(let selectedIndex):
        if !view.adjustView.isHidden {
          view.adjustView.hideAnimated()
          view.switchView.fadeIn()
          view.switchView.selectionIndex = selectedIndex
        }
      case let .adjustControl(min, max, value):
        if view.adjustView.isHidden {
          view.adjustView.configure(with: .init(
            minValue: min,
            maxValue: max,
            value: value
          ))
          view.switchView.fadeOut()
          view.adjustView.showAnimated()
        }
      }
    }
  }
  
  func setBackItem(_ item: BackItem) {
    switch item {
    case .back:
      mainView.backButton.buttonStyle = .back
    case .cancel:
      mainView.backButton.buttonStyle = .cancel
    }
  }

  func setRightItem(_ item: RightItem) {
    switch item {
    case .download:
      mainView.variantsButton.isHidden = true
      mainView.downloadButton.isHidden = false
    case let .variants(selectedIndex, allVariants):
      if !allVariants.isEmpty {
        mainView.variantsButton.configure(with: allVariants[selectedIndex])
        mainView.variantsButton.isHidden = false
      } else {
        mainView.variantsButton.isHidden = true
      }
      mainView.downloadButton.isHidden = true
    }
  }
  
  func setTopControlsVisible(_ visible: Bool) {
    mainView.apply {
      $0.colorPickerButton.isHidden = !visible
    }
  }

  func showVariantsPicker(variants: [VariantViewModel]) {
    let actionController = ActionsViewController(
      actions: variants.enumerated().map { index, variant in
        .init(title: variant.title, image: variant.icon) { [weak self] in
          self?.output.onSelectVariant(at: index)
        }
      },
      sourceView: mainView.variantsButton
    )
    present(actionController, animated: true)
  }
}

// MARK: - ToolsViewDelegate
extension ToolbarViewController: ToolsViewDelegate {
  func toolsView(_ toolsView: ToolsView, didTapItemAt index: Int) {
    output.onTapTool(at: index)
  }
}

// MARK: - SwitchViewDelegate
extension ToolbarViewController: SwitchViewDelegate {
  func switchView(_ switchView: SwitchView, didSwitchedTo index: Int) {
    output.onSwitchToDrawing()
  }
}


// MARK: - AdjustViewDelegate {
extension ToolbarViewController: AdjustViewDelegate {
  func adjustViewValueDidChanged(_ view: AdjustView) {
    output.onAdjust(strokeSize: view.value)
  }
}
