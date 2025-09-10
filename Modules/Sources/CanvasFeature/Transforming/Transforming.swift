import Foundation
import CoreGraphics

public protocol Transforming {
  func transform(_ drawing: Drawing) -> Drawing
  func transform(_ drawings: [Drawing]) -> [Drawing]
}

extension Transforming {
  func transform(_ drawing: Drawing) -> Drawing {
    drawing
  }
  
  func transform(_ drawings: [Drawing]) -> [Drawing] {
    drawings
  }
}
