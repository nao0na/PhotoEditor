import UIKit
import ToolbarFeature
import CanvasFeature

// MARK: - View input
protocol EditorViewInput: AnyObject {
  func setTool(_ tool: CanvasFeature.DrawingStyle)
  func setImage(_ image: UIImage?)
  func getImage() -> CGImage?
}

// MARK: - View output
protocol EditorViewOutput: AnyObject {
  func onViewDidLoad()
}

final public class EditorViewController: UIViewController {
  
  private let output: EditorViewOutput
  
  private let toolbarController: UIViewController?
  
  private lazy var canvasView = CanvasView()
  
  private lazy var undoButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Назад", for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(undoAction), for: .touchUpInside)
    button.setTitleColor(.darkGray, for: .disabled)
    button.setTitleColor(.fromPalette(.text), for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 17)
    button.isEnabled = false
    return button
  }()

  private lazy var clearButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Очистить", for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(clearAction), for: .touchUpInside)
    button.setTitleColor(.fromPalette(.text), for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 17)
    return button
  }()

  // MARK: - Init
  public init(
    image: UIImage?,
    toolbarController: UIViewController? = nil,
    editorDelegate: EditorDelegate? = nil
  ) {
    let presenter = EditorPresenter()
    self.output = presenter
    self.toolbarController = ToolbarViewController(
      delegate: presenter
    )
    super.init(nibName: nil, bundle: nil)
    presenter.view = self
    presenter.delegate = editorDelegate
    presenter.setImage(image)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    canvasView.delegate = self
    
    view.backgroundColor = UIColor.black
        
    view.addSubview(canvasView)
    canvasView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      canvasView.centerXAnchor.constraint(
        equalTo: view.centerXAnchor
      ),
      canvasView.centerYAnchor.constraint(
        equalTo: view.centerYAnchor,
        constant: -50
      )
    ])
    
    toolbarController.map { controller in
      controller.willMove(toParent: self)
      view.addSubview(controller.view)
      controller.view.translatesAutoresizingMaskIntoConstraints = false
      controller.view.clipsToBounds = false
      NSLayoutConstraint.activate([
        controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
        controller.view.rightAnchor.constraint(equalTo: view.rightAnchor),
        controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        controller.view.topAnchor.constraint(equalTo: canvasView.bottomAnchor)
      ])
      addChild(controller)
      controller.didMove(toParent: self)
    }

    view.addSubview(clearButton)
    NSLayoutConstraint.activate([
      clearButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      clearButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
    ])

    view.addSubview(undoButton)
    NSLayoutConstraint.activate([
      undoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      undoButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
    ])
    
  }
  
  @objc private func clearAction() {
    canvasView.clear()
  }
  
  @objc private func undoAction() {
    canvasView.undo()
  }
  
}

// MARK: - EditorViewInput
extension EditorViewController: EditorViewInput {
  func getImage() -> CGImage? {
    canvasView.getImage()
  }
  
  func setImage(_ image: UIImage?) {
    canvasView.image = image
  }
  
  func setTool(_ tool: CanvasFeature.DrawingStyle) {
    canvasView.drawingStyle = tool
  }
}


// MARK: - CanvasViewDelegate
extension EditorViewController: CanvasViewDelegate {
  public func canvasViewDidChanged(_ view: CanvasFeature.CanvasView) {
    undoButton.isEnabled = view.canUndo
  }
}
