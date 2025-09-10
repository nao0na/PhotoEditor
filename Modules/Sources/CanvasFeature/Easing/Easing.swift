import CoreGraphics

func easing(to: CGFloat, time: CGFloat, curve: EasingCurve = .linear) -> CGFloat {
  guard time >= 0, time <= 1 else {
    assertionFailure("time should be in 0...1")
    return to
  }
  return to * curve.compute(time)
}

enum EasingCurve {

  case linear
  case easeInOutCubic
  case easeOutCirc

  func compute(_ t: CGFloat) -> CGFloat {
    switch self {
    case .linear:
      return t
    case .easeInOutCubic:
      return t < 0.5 ? 4 * pow(t, 3) : 1 - pow(-2 * t + 2, 3) / 2
    case .easeOutCirc:
      return sqrt(1 - pow(t - 1, 2))
    }
  }
}
