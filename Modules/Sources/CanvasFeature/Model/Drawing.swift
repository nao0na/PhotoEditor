import CoreGraphics

public struct Drawing {
  public var strokes: [Stroke]
  public let color: CGColor
  public let ink: InkType
  
  init(strokes: [Stroke], color: CGColor, ink: InkType) {
    self.strokes = strokes
    self.color = color
    self.ink = ink
  }
  
  init(points: [Point], color: CGColor, ink: InkType, strokeSize: CGFloat, isClosed: Bool, isFilled: Bool) {
    self.strokes = [Stroke(points: points, strokeSize: strokeSize, isClosed: isClosed, isFilled: isFilled)]
    self.color = color
    self.ink = ink
  }
  
  var pointsCount: Int {
    strokes.reduce(0, {
      $0 + $1.points.count
    })
  }
  
  func with(strokes: [Stroke]? = nil, color: CGColor? = nil, ink: InkType? = nil) -> Self {
    .init(
      strokes: strokes ?? self.strokes,
      color: color ?? self.color,
      ink: ink ?? self.ink
    )
  }
  
  mutating func append(point: Point) {
    if !strokes.isEmpty {
      strokes[strokes.count - 1].append(point: point)
    }
  }
}
