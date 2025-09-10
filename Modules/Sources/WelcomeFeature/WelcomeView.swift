import Core
import Lottie
import UIKit

final class WelcomeView: UIView {
  // MARK: - Subviews

  private lazy var stickerAnimationView: AnimationView = AnimationView(
    name: "sticker",
    bundle: .module
  ).apply {
    $0.loopMode = .loop
    $0.backgroundColor = .clear
    $0.contentMode = .scaleAspectFit
    $0.backgroundBehavior = .pauseAndRestore
    $0.play()
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  private lazy var titleLabel: UILabel = .init(
    frame: .zero
  ).apply {
    $0.text = "Разрешите доступ к вашей медиатеке"
    $0.font = .systemFont(ofSize: 20, weight: .semibold)
    $0.textAlignment = .center
    $0.textColor = .white
    $0.backgroundColor = .black
    $0.numberOfLines = 2
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  private lazy var button: Button = .init(
    frame: .zero
  ).apply {
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - init/deinit

  override init(frame: CGRect) {
    super.init(frame: frame)

    setup()
    configure(with: .initial)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Public methods

  func configure(with viewModel: ViewModel) {
    button.text = viewModel.title
    button.onTap = viewModel.onTap
  }

  // MARK: - Private methods

  private func setup() {
    backgroundColor = .black

    addSubview(stickerAnimationView)
    addSubview(titleLabel)
    addSubview(button)

    NSLayoutConstraint.activate([
      stickerAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor),
      stickerAnimationView.bottomAnchor.constraint(equalTo: centerYAnchor),
      stickerAnimationView.widthAnchor.constraint(equalToConstant: 144),
      stickerAnimationView.heightAnchor.constraint(equalToConstant: 144),

      titleLabel.leadingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.leadingAnchor,
        constant: 16
      ),
      titleLabel.trailingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.trailingAnchor,
        constant: -16
      ),
      titleLabel.topAnchor.constraint(
        equalTo: stickerAnimationView.bottomAnchor,
        constant: 20
      ),

      button.leadingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.leadingAnchor,
        constant: 16
      ),
      button.trailingAnchor.constraint(
        equalTo: safeAreaLayoutGuide.trailingAnchor,
        constant: -16
      ),
      button.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: 28
      ),
      button.heightAnchor.constraint(equalToConstant: 50)
    ])
  }
}

// MARK: - ViewModel

extension WelcomeView {
  struct ViewModel {
    let title: String?
    let onTap: Command

    static var initial: ViewModel {
      return ViewModel(
        title: nil,
        onTap: .nop
      )
    }
  }
}
