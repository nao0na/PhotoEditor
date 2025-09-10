import CoreGraphics

final class LerpTransformer: Transforming {
  
  
  private let iterations: Int
  
  init(iterations: Int) {
    self.iterations = iterations
  }
  
  // MARK: - Transforming
  func transform(_ drawing: Drawing) -> Drawing {
    return drawing.with(strokes: drawing.strokes.enumerated().map { strokeIndex, stroke in
      guard stroke.points.count > 2, strokeIndex == 0 else {
        return stroke
      }
      
      var points = stroke.points
      
      let startIndex = 1
      let endIndex = stroke.points.count - 2
      
      for _ in 0..<iterations {
        for i in startIndex...endIndex {
          let prev = points[i - 1]
          let current = points[i]
          let next = points[i + 1]
          
          points[i] = current.with(
            location: prev.location.lerp(to: next.location, t: 0.5)
          )
        }
      }
      return stroke.with(points: points)
    })
  }
  
}

