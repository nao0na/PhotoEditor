import UIKit

protocol VariantViewModel {
  var title: String { get }
  var icon: UIImage? { get }
}


// MARK: - ToolbarState.Tool.Variant + VariantViewModel
extension ToolbarState.Tool.Variant: VariantViewModel {
  var title: String {
    switch self {
    case .round:
      return "Круг"
    case .arrow:
      return "Стрела"
    case .blur:
      return "Блюр"
    case .eraser:
      return "Ластик"
    }
  }
  
  var icon: UIImage? {
    switch self {
    case .round, .eraser:
      return UIImage(named: "roundTip", in: .module, with: nil)
    case .arrow:
      return UIImage(named: "arrowTip", in: .module, with: nil)
    case .blur:
      return UIImage(named: "blurTip", in: .module, with: nil)
    }
  }
}
