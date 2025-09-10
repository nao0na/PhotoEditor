import UIKit

public struct ToolbarState {
  public var tools: [Tool]
  public var mode: Mode
  public var selectedIndex: Int
  
  public init(
    tools: [Tool],
    mode: Mode,
    selectedIndex: Int = 0
  ) {
    self.tools = tools
    self.mode = mode
    self.selectedIndex = selectedIndex
  }
}
// MARK: - Initial state
public extension ToolbarState {
  static var `default`: Self {
    .init(
      tools: [
        .init(
          tool: .pen,
          variant: .round,
          variants: [.round, .arrow],
          color: .white,
          strokeSize: 10
        ),
        .init(
          tool: .marker,
          variant: .round,
          color: .blue,
          strokeSize: 10
        ),
//        .init(
//          tool: .neon,
//          variant: .round,
//          variants: [.round, .arrow],
//          color: .red,
//          strokeSize: 10
//        ),
        .init(
          tool: .pencil,
          variant: .round,
          color: .green,
          strokeSize: 10
        ),
//        .init(tool: .lasso),
        .init(
          tool: .eraser,
          variant: .eraser,
          variants: [.eraser, .blur],
          strokeSize: 72,
          maxStrokeSize: 72
        ),
      ],
      mode: .drawing
    )
  }
}

// MARK: - Utils
public extension ToolbarState {
  
  var selectedTool: Tool {
    tools[selectedIndex]
  }
  
  var color: UIColor? {
    tools[selectedIndex].color
  }
}

// MARK: - Nested types

public extension ToolbarState {
  
  enum Mode {
    case drawing
    case adjusting
  }

  struct Tool {
    
    public let tool: Tool
    public let variant: Variant
    public let variants: [Variant]
    public let color: UIColor?
    public let strokeSize: CGFloat
    public let minStrokeSize: CGFloat
    public let maxStrokeSize: CGFloat

    public init(
      tool: Tool,
      variant: Variant = .round,
      variants: [Variant] = [],
      color: UIColor? = nil,
      strokeSize: CGFloat = 24,
      minStrokeSize: CGFloat = 4,
      maxStrokeSize: CGFloat = 48
    ) {
      self.tool = tool
      self.variant = variant
      self.variants = variants
      self.color = color
      self.strokeSize = strokeSize
      self.minStrokeSize = minStrokeSize
      self.maxStrokeSize = maxStrokeSize
    }
    
    public enum Tool {
      case pen
      case pencil
      case marker
      case eraser
    }
    
    public enum Variant {
      case round
      case arrow
      case eraser
      case blur
    }
    
    func with(variant: Variant? = nil, color: UIColor? = nil, strokeSize: CGFloat? = nil) -> Self {
      .init(
        tool: tool,
        variant: variant ?? self.variant,
        variants: variants,
        color: color ?? self.color,
        strokeSize: strokeSize ?? self.strokeSize
      )
    }
  }
}


extension ToolbarState.Tool: Equatable {}
