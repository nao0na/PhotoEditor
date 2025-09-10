import Foundation
import CoreGraphics

extension CGPoint{
  
  func translate(x: CGFloat, _ y: CGFloat) -> CGPoint {
    .init(x: self.x + x, y: self.y + y)
  }
  
  func translateX(x: CGFloat) -> CGPoint {
    .init(x: self.x + x, y: y)
  }
  
  func translateY(y: CGFloat) -> CGPoint {
    .init(x: x, y: self.y + y)
  }
  
  func invertY() -> CGPoint {
    .init(x: x, y: -self.y)
  }
  
  func xAxis() -> CGPoint {
    .init(x: 0, y: y)
  }
  
  func yAxis() -> CGPoint {
    .init(x: x, y: 0)
  }
  
  func addTo(a: CGPoint) -> CGPoint {
    .init(x: self.x + a.x, y: self.y + a.y)
  }
  
  func deltaTo(a: CGPoint) -> CGPoint {
    .init(x: self.x - a.x, y: self.y - a.y)
  }
  
  func multiplyBy(value:CGFloat) -> CGPoint{
    .init(x: self.x * value, y: self.y * value)
  }
  
  func length() -> CGFloat {
    sqrt(pow(x, 2) + pow(y, 2))
  }
  
  func normalize() -> CGPoint {
    let l = length()
    return .init(x: x / l, y: y / l)
  }

  func lerp(to: CGPoint, t: CGFloat) -> CGPoint {
    .init(
      x: x + (to.x - x) * t,
      y: y + (to.y - y) * t
    )
  }
  
  func distance(to point: CGPoint) -> CGFloat {
    let dx = abs(point.x - x)
    let dy = abs(point.y - y)
    return sqrt(pow(dx, 2) + pow(dy, 2))
  }
  
}
