import CoreGraphics

public struct Stroke {
  public var points: [Point]
  public let strokeSize: CGFloat
  public let isClosed: Bool
  public let isFilled: Bool
  
  mutating func append(point: Point) {
    points.append(point)
  }
  
  init(points: [Point], strokeSize: CGFloat, isClosed: Bool, isFilled: Bool) {
    self.points = points
    self.strokeSize = strokeSize
    self.isClosed = isClosed
    self.isFilled = isFilled
  }
  
  func with(points: [Point]? = nil, strokeSize: CGFloat? = nil, isClosed: Bool? = nil, isFilled: Bool? = nil) -> Self {
    .init(
      points: points ?? self.points,
      strokeSize: strokeSize ?? self.strokeSize,
      isClosed: isClosed ?? self.isClosed,
      isFilled: isFilled ?? self.isFilled
    )
  }
}

extension Stroke: Hashable {}

extension Stroke {
  
  var start: CGPoint {
    points.first?.location ?? .zero
  }
  
  var end: CGPoint {
    points.last?.location ?? .zero
  }
  
  var isEmpty: Bool {
    points.isEmpty
  }
  
  var frame: CGRect {
    if
    let left = points.min(by: { $0.location.x < $1.location.x }),
    let right = points.max(by: { $0.location.x < $1.location.x }),
    let top = points.min(by: { $0.location.y < $1.location.y }),
    let bottom = points.max(by: { $0.location.y < $1.location.y }) {
      return .init(
        x: left.location.x,
        y: top.location.y,
        width: right.location.x - left.location.x,
        height: bottom.location.y - top.location.y
      )
    }
    return .zero
  }
  
}
