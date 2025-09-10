import Core
import UIKit

final class Button: UIControl {
  // MARK: - Subviews

  private lazy var titleLabel: UILabel = .init(
    frame: .zero
  ).apply {
    $0.font = .systemFont(ofSize: 17, weight: .semibold)
    $0.numberOfLines = 1
    $0.textAlignment = .center
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - Properties

  var text: String? = nil {
    didSet {
      titleLabel.text = text
    }
  }

  var onTap: Command = .nop

  // MARK: - init/deinit

  override init(frame: CGRect) {
    super.init(frame: frame)

    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Private methods

  private func setup() {
    backgroundColor = UIColor(hexP3: "#007AFF")
    layer.cornerRadius = 10
    layer.masksToBounds = true

    addSubview(titleLabel)

    addTarget(
      self,
      action: #selector(Button.onTapHandle),
      for: .touchUpInside
    )

    titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
  }

  @objc private func onTapHandle() {
    onTap.perform()
  }
}
