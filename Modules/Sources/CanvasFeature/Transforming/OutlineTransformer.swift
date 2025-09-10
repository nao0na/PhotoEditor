
import Foundation
import CoreGraphics

final class OutlineTransformer: Transforming {
  
  private let outlineWidth: CGFloat = 1
  private let tailLength: CGFloat = 150
  
  private let dynamicWidth: Bool
  
  init(dynamicWidth: Bool) {
    self.dynamicWidth = dynamicWidth
  }
  
  // MARK: - Transforming
  func transform(_ drawing: Drawing) -> Drawing {
    return drawing.with(strokes: drawing.strokes.enumerated().map { strokeIndex, stroke in
      guard !stroke.points.isEmpty,
            strokeIndex == 0 else {
        return stroke
      }
      
      var leftPoints = [Point]()
      var rightPoints = [Point]()
      var distance: CGFloat = 0
      
      var totalDistance: CGFloat = 0
      var speed: [CGFloat] = [0]
      
      if stroke.points.count > 2 {
        for i in 1..<(stroke.points.count - 1) {
          let prevPoint = stroke.points[i - 1]
          let curPoint = stroke.points[i]
          totalDistance += abs(prevPoint.distance(to: curPoint))
          speed.append(prevPoint.speed(to: curPoint) / 10000)
        }
      }
      speed = smooth(speed, ratio: 0.5)
      let endTime = stroke.points.last?.time ?? 0
      for index in 0..<(stroke.points.count - 1) {
        if index == 0 {
          leftPoints.append(stroke.points[index])
          continue
        }
        
        if index == stroke.points.count - 1 {
          leftPoints.append(stroke.points[index])
          continue
        }
        let point = stroke.points[index]
        let prevPoint = stroke.points[index - 1]
        let nextPoint = stroke.points[index + 1]
        let dir = point.distance(to: nextPoint)
        
        let size = normalWidth(
          time: endTime > 0 ? point.time / endTime : 1,
          distance: distance,
          distanceRemain: max(0, totalDistance - distance),
          speed: speed[index],
          strokeSize: stroke.strokeSize
        )
        distance += abs(dir)
        
        let nAngle = normalAngle(p1: prevPoint, p2: nextPoint)
        let x = size * sin(nAngle)
        let y = size * sin(.pi / 2 - nAngle)
        
        if !x.isNaN, !y.isNaN {
          
          let p1 = point
            .with(location: .init(
              x: point.location.x + x,
              y: point.location.y + y
            ))
          
          
          // left point
          let x2 = -x
          let y2 = -y
          let p2 = point
            .with(
              location: .init(
                x: point.location.x + x2,
                y: point.location.y + y2
              ),
              time: endTime + stroke.points[stroke.points.count - index - 1].time
            )
          
          
          rightPoints.append(p2)
          leftPoints.append(p1)
        }
      }
      
      return stroke.with(
        points: leftPoints.reversed() + rightPoints,
        isClosed: true,
        isFilled: true
      )
    })
  }
  
  private func normalAngle(p1: Point, p2: Point) -> CGFloat {
    let dx = p2.location.x - p1.location.x
    let dy = p2.location.y - p1.location.y
    let dir = sqrt(pow(dx, 2) + pow(dy, 2))
    let a = .pi/2 + acos(dx / dir) * (dy < 0 ? -1 : 1)
    return .pi / 2 - a
  }
  
  
  private func normalWidth(
    time: CFTimeInterval,
    distance: CGFloat,
    distanceRemain: CGFloat,
    speed: CGFloat,
    strokeSize: CGFloat
  ) -> CGFloat {
    guard dynamicWidth else {
      return strokeSize
    }
    let kSpeed = max(0.3, min(1.5, 1 - speed))
    
    if distance < tailLength  {
      return kSpeed * easing(to: strokeSize, time: min(1, distance / tailLength), curve: .easeOutCirc)
    }
    
    if distanceRemain < tailLength {
      return kSpeed * easing(to: strokeSize, time: min(1, distanceRemain / tailLength), curve: .easeOutCirc)
    }
    
    return strokeSize * kSpeed
  }
  
  private func smooth(_ numbers: [CGFloat], ratio: CGFloat, passes: Int = 1) -> [CGFloat] {
    guard numbers.count >= 3 else {
      return numbers
    }
    var smothed = numbers
    for _ in 0...passes {
      for i in 1..<(smothed.count - 1) {
        let prev = numbers[i - 1]
        let next = numbers[i + 1]
        smothed[i] = prev + (next - prev) * ratio
      }
    }
    return smothed
  }
  
}
