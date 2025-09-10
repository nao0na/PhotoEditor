import UIKit

// MARK: - Output
public protocol ToolbarDelegate: AnyObject {
  func toolBarHasChanges(_ toolbar: Toolbar)
  func toolbarDidTapCancelButton(_ toolbar: Toolbar)
  func toolbarDidTapDownloadButton(_ toolbar: Toolbar)
}


// MARK: - Input
public protocol Toolbar: AnyObject {
  var mode: ToolbarState.Mode { get }
  var tools: [ToolbarState.Tool] { get }
  
  var selectedTool: ToolbarState.Tool { get set }
  var color: UIColor? { get set }
  var strokeSize: CGFloat { get set }
  var variant: ToolbarState.Tool.Variant { get set }
}

final class ToolbarPresenter: NSObject {
  
  weak var view: ToolbarViewInput?
  var router: ToolbarRouter?
  
  private weak var delegate: ToolbarDelegate?

  private var state: ToolbarState {
    didSet {
      delegate?.toolBarHasChanges(self)
    }
  }
  
  init(initialState: ToolbarState, delegate: ToolbarDelegate?) {
    self.state = initialState
    self.delegate = delegate
  }
  
  private func reloadView() {
    
    view?.updateToolbar(item: state.selectedTool, at: state.selectedIndex)

    state.color.map {
      view?.setPickedColor($0)
    }
              
    switch state.mode {
    case .drawing:
      view?.setTopControlsVisible(true)
      view?.setBottomItem(.switchControl(selectedIndex: 0))
      view?.selectItem(at: state.selectedIndex)
      view?.setBackItem(.cancel)
      view?.setRightItem(.download)
      view?.setCenterItem(.toolBar)
    case .adjusting:
      view?.setTopControlsVisible(false)
      view?.setBottomItem(.adjustControl(
        min: selectedTool.minStrokeSize,
        max: selectedTool.maxStrokeSize,
        value: state.selectedTool.strokeSize
      ))
      view?.pickItem(at: state.selectedIndex)
      view?.setBackItem(.back)
      view?.setRightItem(.variants(
        selectedIndex: state.selectedTool.variants.firstIndex(of: state.selectedTool.variant) ?? 0,
        allVariants: state.selectedTool.variants
      ))
      view?.setCenterItem(.toolBar)
    }
  }
}

// MARK: - EditorViewOutput
extension ToolbarPresenter: ToolbarViewOutput {
  
  func onViewDidLoad() {
    delegate?.toolBarHasChanges(self)
  }
  
  func onTapTool(at index: Int) {
    switch state.mode {
    case .drawing:
      if index == state.selectedIndex {
        state.mode = .adjusting
      } else {
        state.mode = .drawing
      }
    case .adjusting:
      state.mode = .drawing
    }
    
    state.selectedIndex = index
        
    reloadView()
  }

  func onViewDidAppear() {
    view?.setupToolbar(items: state.tools)
    reloadView()
  }
  
  func onSwitchToDrawing() {
    state.mode = .drawing
    reloadView()
  }
  
  func onAdjust(strokeSize: CGFloat) {
    state.tools[state.selectedIndex] = state.selectedTool.with(strokeSize: strokeSize)
    reloadView()
  }
  
  func onBackButtonTapped() {
    switch state.mode {
    case .drawing:
      delegate?.toolbarDidTapCancelButton(self)
    case .adjusting:
      state.mode = .drawing
      reloadView()
    }
  }
  
  func onSelectVariant(at index: Int) {
    let selectedTool = state.selectedTool
    let selectedIndex = state.selectedIndex
    let variants = selectedTool.variants
    if !variants.isEmpty {
      state.tools[selectedIndex] = selectedTool.with(variant: variants[index])
    }
    reloadView()
  }
  
  func onTapVariantButton() {
    if !state.selectedTool.variants.isEmpty {
      view?.showVariantsPicker(variants: state.selectedTool.variants)
    }
  }
  
  func onTapColorPickerButton() {
    router?.presentColorPicker(self)
  }
  
  func onTapDownloadButton() {
    delegate?.toolbarDidTapDownloadButton(self)
  }
}


// MARK: - Editor protocol
extension ToolbarPresenter: Toolbar {
  var mode: ToolbarState.Mode {
    state.mode
  }
  
  var tools: [ToolbarState.Tool] {
    state.tools
  }
  
  var selectedTool: ToolbarState.Tool {
    get {
      state.selectedTool
    }
    set {
      if let index = state.tools.firstIndex(of: newValue) {
        state.selectedIndex = index
        reloadView()
      }
    }
  }
  
  var color: UIColor? {
    get {
      state.color
    }
    set {
      state.tools[state.selectedIndex] = state.selectedTool.with(color: newValue)
      reloadView()
    }
  }
  
  var strokeSize: CGFloat {
    get {
      state.selectedTool.strokeSize
    }
    set {
      state.tools[state.selectedIndex] = state.selectedTool.with(strokeSize: newValue)
      reloadView()
    }
  }
  
  var variant: ToolbarState.Tool.Variant {
    get {
      state.selectedTool.variant
    }
    set {
      state.tools[state.selectedIndex] = state.selectedTool.with(variant: newValue)
      reloadView()
    }
  }
}

// MARK: - UIColorPickerViewControllerDelegate

extension ToolbarPresenter: UIColorPickerViewControllerDelegate {
  func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
    state.tools[state.selectedIndex] = state.selectedTool.with(color: color)
    reloadView()
  }
}
