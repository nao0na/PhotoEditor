import UIKit

final class VariantsButton: UIControl {
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 1
    label.textAlignment = .right
    return label
  }()
  
  private lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  // MARK: - Init
  
  init() {
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup view
  private func setup() {
    
    addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 24),
      imageView.heightAnchor.constraint(equalToConstant: 24),
      imageView.rightAnchor.constraint(equalTo: rightAnchor),
      imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
    
    addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: leftAnchor),
      titleLabel.rightAnchor.constraint(equalTo: imageView.leftAnchor, constant: -4),
      titleLabel.topAnchor.constraint(equalTo: topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction)))
  }
  
  // MARK: - Configure
  func configure(with viewModel: VariantViewModel) {
    titleLabel.text = viewModel.title
    imageView.image = viewModel.icon
  }
  
  @objc private func tapAction() {
    sendActions(for: .touchUpInside)
  }

}
