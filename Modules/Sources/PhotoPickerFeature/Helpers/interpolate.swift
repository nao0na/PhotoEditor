import Foundation
import CoreGraphics

internal func interpolate(
  from: CGFloat,
  to: CGFloat,
  progress: CGFloat
) -> CGFloat {
  assert(progress >= 0.0 && progress <= 1.0)
  return from + (to - from) * progress
}
