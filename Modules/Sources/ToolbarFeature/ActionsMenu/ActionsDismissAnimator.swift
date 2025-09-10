import UIKit

final class ActionsDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  private let targetView: UIView
  private let animationDuration: TimeInterval
  
  init(targetView: UIView, animationDuration: TimeInterval = 0.4) {
    self.targetView = targetView
    self.animationDuration = animationDuration
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    animationDuration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
    guard
      let fromView = transitionContext.view(forKey: .from) else {
      return
    }

    UIView.animate(
      withDuration: animationDuration,
      delay: 0,
      usingSpringWithDamping: 0.8,
      initialSpringVelocity: 1,
      animations: {
        fromView.transform = .init(scaleX: 0.5, y: 0.5)
        fromView.alpha = 0
      }, completion: { _ in
        fromView.removeFromSuperview()
        transitionContext.completeTransition(true)
    })

  }
}
