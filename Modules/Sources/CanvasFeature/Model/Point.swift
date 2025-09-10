import CoreGraphics

public struct Point {
  public let location: CGPoint
  public let time: CFTimeInterval
  public let force: CGFloat
}

extension Point {
  
  func with(
    location: CGPoint? = nil,
    time: CFTimeInterval? = nil,
    force: CGFloat? = nil
  ) -> Self {
    .init(
      location: location ?? self.location,
      time: time ?? self.time,
      force: force ?? self.force
    )
  }
  
  func distance(to point: Point) -> CGFloat {
    let dx = abs(point.location.x - location.x)
    let dy = abs(point.location.y - location.y)
    return sqrt(pow(dx, 2) + pow(dy, 2))
  }
  
  func speed(to point: Point) -> CGFloat {
    abs(distance(to: point)) / (point.time - time)
  }
  
}

extension Point: Equatable { }

extension Point: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(location.x)
    hasher.combine(location.y)
  }
}
