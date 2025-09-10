import Core
import UIKit

protocol WelcomeViewInput: AnyObject {
  func configure(with viewModel: WelcomeView.ViewModel)
}

protocol WelcomeViewOutput: AnyObject {
  func onViewDidLoad()
}

public final class WelcomeViewController: UIViewController {
  // MARK: - Subviews

  private lazy var mainView: WelcomeView = .init(
    frame: .zero
  )

  // MARK: - Properties

  private let viewOutput: WelcomeViewOutput

  // MARK: - init/deinit

  public init(onFinish: Command) {
    let presenter = WelcomePresenter(onFinish: onFinish)
    self.viewOutput = presenter

    super.init(nibName: nil, bundle: nil)

    presenter.view = self
    transitioningDelegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Override properties

  public override var modalPresentationStyle: UIModalPresentationStyle {
    get { return UIModalPresentationStyle.fullScreen }
    set {}
  }

  // MARK: - VC lifecycle

  public override func loadView() {
    view = mainView
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    viewOutput.onViewDidLoad()
  }
}

// MARK: - WelcomeViewInput

extension WelcomeViewController: WelcomeViewInput {
  func configure(with viewModel: WelcomeView.ViewModel) {
    mainView.configure(with: viewModel)
  }
}

// MARK: - UIViewControllerTransitioningDelegate

extension WelcomeViewController: UIViewControllerTransitioningDelegate {
  public func animationController(
    forDismissed dismissed: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    return WelcomeViewControllerCloseAnimatedTransitioning()
  }
}
