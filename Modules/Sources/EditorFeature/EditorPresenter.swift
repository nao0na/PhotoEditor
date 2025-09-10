import Foundation
import ToolbarFeature
import CanvasFeature
import UIKit

public protocol Editor: AnyObject {
  func setImage(_ image: UIImage?)
}

public protocol EditorDelegate: AnyObject {
  func editorDidCancel(_ editor: Editor)
  func editor(_ editor: Editor, didFinishWith image: CGImage?)
}

final class EditorPresenter: NSObject, Editor {
  weak var view: EditorViewInput?
  
  weak var delegate: EditorDelegate?
  
  // MARK: - Editor
  func setImage(_ image: UIImage?) {
    view?.setImage(image)
  }

}


// MARK: - EditorViewOutput
extension EditorPresenter: EditorViewOutput {
  
  func onViewDidLoad() {
    
  }
  
}

extension EditorPresenter: ToolbarDelegate {
    
  func toolBarHasChanges(_ toolbar: Toolbar) {
    let toolbarTool = toolbar.selectedTool
    let color = toolbarTool.color ?? .white
    let strokeSize = toolbarTool.strokeSize
    
    let tipType: TipType = toolbarTool.variant == .arrow ? .arrow : .default
    
    switch toolbarTool.tool {
    case .pen:
      view?.setTool(.pen(
        strokeSize: strokeSize,
        color: color,
        tipType: tipType
      ))
    case .pencil:
      view?.setTool(.pencil(
        strokeSize: strokeSize,
        color: color,
        tipType: tipType
      ))
    case .marker:
      view?.setTool(.marker(
        strokeSize: strokeSize,
        color: color,
        tipType: tipType
      ))
    case .eraser:
      switch toolbarTool.variant {
      case .eraser:
        view?.setTool(.erase(strokeSize: strokeSize))
      case .blur:
        view?.setTool(.blur(strokeSize: strokeSize))
      default:
        break
      }
    }
  }
  
  func toolbarDidTapCancelButton(_ toolbar: Toolbar) {
    delegate?.editorDidCancel(self)
  }
  
  func toolbarDidTapDownloadButton(_ toolbar: ToolbarFeature.Toolbar) {
      guard let image = view?.getImage()
      else { return }
      delegate?.editor(self, didFinishWith: image)
  }
}
