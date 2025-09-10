import UIKit

final class ActionsPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  private let sourceView: UIView
  private let animationDuration: TimeInterval
  
  init(sourceView: UIView, animationDuration: TimeInterval = 0.4) {
    self.sourceView = sourceView
    self.animationDuration = animationDuration
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    animationDuration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
    guard
      let toController = transitionContext.viewController(forKey: .to),
      let toView = transitionContext.view(forKey: .to) else {
      return
    }
    
    let containerView = transitionContext.containerView
    let sourceRect = sourceView.superview!.convert(sourceView.frame, to: containerView)
    
    let toSize = toController.preferredContentSize
    
    let finalRect = CGRect(
      x: sourceRect.maxX - toSize.width,
      y: sourceRect.minY - toSize.height - 20,
      width: toSize.width,
      height: toSize.height
    )
    
    toView.layer.cornerRadius = 16
    toView.layer.masksToBounds = true
    toView.layer.anchorPoint = .init(x: 1, y: 1)
    toView.frame = finalRect
    toView.transform = .init(scaleX: 0.5, y: 0.5)
    toView.alpha = 0
    

    
    let overlayView = OverlayView {
      toController.dismiss(animated: true)
    }
    
    overlayView.frame = containerView.bounds
  
    containerView.addSubview(overlayView)
    containerView.addSubview(toView)
    containerView.bringSubviewToFront(toView)

    UIView.animate(
      withDuration: animationDuration,
      delay: 0,
      usingSpringWithDamping: 0.8,
      initialSpringVelocity: 1,
      animations: {
        toView.transform = .identity
        toView.alpha = 1
      }, completion: { _ in
        transitionContext.completeTransition(true)
    })

  }

}

fileprivate final class OverlayView: UIView {
  
  private let tapHandler: () -> Void
  
  init(tapHandler: @escaping () -> Void) {
    self.tapHandler = tapHandler
    super.init(frame: .zero)
    isUserInteractionEnabled = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    tapHandler()
  }
  
}
