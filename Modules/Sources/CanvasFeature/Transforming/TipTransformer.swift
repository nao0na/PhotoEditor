import Foundation
import CoreGraphics

final class TipTransformer: Transforming {
  
  private let tip: Tip
  
  init(tip: Tip) {
    self.tip = tip
  }
  
  func transform(_ drawing: Drawing) -> Drawing {
    guard tip == .arrow,
          let mainStroke = drawing.strokes.first,
          mainStroke.points.count > 1
    else {
      return drawing
    }
    let size: CGFloat = mainStroke.strokeSize * 4
    
    var distance: CGFloat = 0
    var pointIndex = mainStroke.points.count - 1
    while distance < size, pointIndex > 0 {
      let p1 = mainStroke.points[pointIndex-1]
      let p2 = mainStroke.points[pointIndex]
      distance += p1.distance(to: p2)
      pointIndex -= 1
    }

    if distance < size {
      return drawing
    }
    
    let firstPoint = distance > size * 1.5 ? pivotPoint(
      p1: mainStroke.points[mainStroke.points.count - 2],
      p2: mainStroke.points[mainStroke.points.count - 1],
      distance: size
    ) : mainStroke.points[pointIndex]
    
    let lastPoint = mainStroke.points[mainStroke.points.count - 1]
    
    let nAngle = normalAngle(p1: firstPoint, p2: lastPoint)
    let x = size * sin(nAngle)
    let y = size * sin(.pi / 2 - nAngle)
    let x2 = -x
    let y2 = -y
    
    let arrowStart = Point(
      location: .init(x: firstPoint.location.x + x, y: firstPoint.location.y + y),
      time: firstPoint.time,
      force: 0
    )
    let arrowEnd = Point(
      location: .init(x: firstPoint.location.x + x2, y: firstPoint.location.y + y2),
      time: lastPoint.time,
      force: 0
    )
    
    let arrowStroke = Stroke(
      points: [
        arrowStart,
        lastPoint,
        arrowEnd
      ],
      strokeSize: mainStroke.strokeSize * 1.5,
      isClosed: false,
      isFilled: false
    )
    
    return drawing.with(
      strokes: [
        mainStroke,
        arrowStroke
      ]
    )
  }
  
  
  private func normalAngle(p1: Point, p2: Point) -> CGFloat {
    let dx = (p2.location.x - p1.location.x) * 10
    let dy = (p2.location.y - p1.location.y) * 10
    let dir = sqrt(pow(dx, 2) + pow(dy, 2))
    let a = .pi/2 + acos(dx / dir) * (dy < 0 ? -1 : 1)
    return .pi / 2 - a
  }
  
  private func pivotPoint(p1: Point, p2: Point, distance: CGFloat) -> Point {
    let dx = p2.location.x - p1.location.x
    let dy = p2.location.y - p1.location.y
    let k = dy / dx
    
    if k.isInfinite {
      return p2.with(location: .init(
        x: p2.location.x,
        y: p2.location.y - (dy > 0 ? distance : -distance)
      ))
    }
    
    let f = { (x: CGFloat) -> CGFloat in
      k * (x - p1.location.x) + p1.location.y
    }
    var d: CGFloat = 0
    
    let delta = dx > 0 ? -0.01 : 0.01
    let to: CGFloat = dx > 0 ? p1.location.x - distance : p1.location.x + distance
    for x in stride(from: p2.location.x, to: to, by: delta) {
      let point = CGPoint(x: x, y: f(x))
      d = point.distance(to: p2.location)
      if d >= distance {
        return p2.with(location: point)
      }
    }
    
    return p1
  }
}

extension TipTransformer {
  enum Tip {
    case `default`
    case arrow
    
    init(_ tipType: TipType) {
      switch tipType {
      case .default:
        self = .default
      case .arrow:
        self = .arrow
      }
    }
  }
}
