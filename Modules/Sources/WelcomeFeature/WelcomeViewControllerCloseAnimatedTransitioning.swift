import UIKit

final class WelcomeViewControllerCloseAnimatedTransitioning: NSObject {
  // MARK: - init/deinit

  override init() {
    super.init()
  }
}

// MARK: - UIViewControllerAnimatedTransitioning

extension WelcomeViewControllerCloseAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
  func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?
  ) -> TimeInterval {
    return Constants.animationDuration
  }

  func animateTransition(
    using transitionContext: UIViewControllerContextTransitioning
  ) {
    guard let fromVC = transitionContext.viewController(forKey: .from),
          let toVC = transitionContext.viewController(forKey: .to)
    else { return }

    let containerView = transitionContext.containerView
    containerView.backgroundColor = .clear

    fromVC.view.frame = containerView.bounds

    let gradientView: GradientView = .init(
      colors: [UIColor.clear, UIColor.black],
      startPoint: .init(x: 0.5, y: 0),
      endPoint: .init(x: 0.5, y: 0.2),
      frame: containerView.bounds
    )

    guard let snapshotFromView = fromVC.view.snapshotView(afterScreenUpdates: true),
          let snapshotGradientView = gradientView.snapshotView(afterScreenUpdates: true)
    else { return }

    containerView.addSubview(toVC.view)
    containerView.insertSubview(snapshotGradientView, aboveSubview: toVC.view)
    containerView.insertSubview(snapshotFromView, aboveSubview: snapshotGradientView)

    UIView.animate(
      withDuration: Constants.animationDuration - 0.1,
      delay: 0,
      options: .curveEaseInOut,
      animations: {
        snapshotFromView.alpha = 0
      },
      completion: { _ in
        snapshotFromView.removeFromSuperview()
      }
    )

    UIView.animate(
      withDuration: Constants.animationDuration,
      delay: 0,
      options: .curveEaseOut,
      animations: {
        snapshotGradientView.transform = CGAffineTransform(
          translationX: 0,
          y: snapshotGradientView.frame.height
        )
      },
      completion: { _ in
        if transitionContext.transitionWasCancelled {
          return
        }

        snapshotGradientView.removeFromSuperview()

        transitionContext.completeTransition(
          transitionContext.transitionWasCancelled == false
        )
      }
    )
  }
}

// MARK: - Constants

private extension WelcomeViewControllerCloseAnimatedTransitioning {
  enum Constants {
    static var animationDuration: TimeInterval {
      return 0.33
    }
  }
}
