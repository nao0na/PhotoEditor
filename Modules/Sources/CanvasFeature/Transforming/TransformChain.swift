import Foundation
import CoreGraphics

struct TransformChain: Transforming {
  
  private let transformers: [Transforming]
  
  init(_ transformers: [Transforming]) {
    self.transformers = transformers
  }
  
  // MARK: - Transforming
  func transform(_ drawing: Drawing) -> Drawing {
    var drawing = drawing
    transformers.forEach { transformer in
      drawing = transformer.transform(drawing)
    }
    return drawing
  }
}
