import Core
import UIKit
import Alloy
import MetalKit

public protocol CanvasViewDelegate: AnyObject {
  func canvasViewDidChanged(_ view: CanvasView)
}

public final class CanvasView: UIView {

  // MARK: - Public props
  
  public weak var delegate: CanvasViewDelegate?
  
  public var image: UIImage? {
    didSet {
      resetImageTexture()
      setupInkRenderer(style: drawingStyle)
    }
  }
  
  public var drawingStyle: DrawingStyle? {
    didSet {
      setupInkRenderer(style: drawingStyle)
    }
  }
  private var inkRenderer: InkRenderer?
  
  // MARK: - Private props
  
  private(set) var items: [Item] = []
  
  private var drawing: Drawing?
  private var timeStart: CFTimeInterval = 0
  
  private var transforming: Transforming?
  
  private var geometryTransform = TransformChain([])
  
  private lazy var metalView: MTKView = {
    let view = MTKView()
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.delegate = self
    view.device = metalContext.device
    view.depthStencilPixelFormat = .invalid
    return view
  }()
  
  private var metalContext = try! MTLContext()
  private var drawingContext: CGContext?
  
  private var imageTexture: MTLTexture?
  private var drawingTexture: MTLTexture?

  private var renderState: MTLRenderPipelineState?
  
  // MARK: - Init
  
  public init() {
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override var intrinsicContentSize: CGSize {
      var insets = UIEdgeInsets()
      insets.top += 60
      insets.bottom += 200
      let imageSize = image?.size ?? .zero
      let superviewSize = superview?.frame.inset(by: insets) ?? .zero
      let widthRatio = superviewSize.width / imageSize.width
      let heightRatio = superviewSize.height / imageSize.height
      let resultWidth = imageSize.width * heightRatio
      let resultHeight = imageSize.height * widthRatio

      if resultHeight < superviewSize.height {
          return CGSize(width: superviewSize.width, height: resultHeight)
      }
      else {
          return CGSize(width: resultWidth, height: superviewSize.height)
      }
  }
  
  // MARK: - Public
 
  public var canUndo: Bool {
    items.count > 0
  }
  
  public func clear() {
    items = []
    drawing = nil

    drawingContext.map { context in
      context.setFillColor(UIColor.clear.cgColor)
      context.clear(.init(x: 0, y: 0, width: context.width, height: context.height))
    }

    resetImageTexture()
    setupInkRenderer(style: drawingStyle, preserveTexture: false)
    delegate?.canvasViewDidChanged(self)
  }
  
  public func undo() {
    guard canUndo else { return }
    items = items.dropLast()
    redraw()
  }
  
  private func redraw() {
    guard let context = drawingContext else {
      return
    }
    
    resetImageTexture()
    clearDrawingContext()
    setupInkRenderer(style: drawingStyle, preserveTexture: false)
    inkRenderer?.update()
    
    for item in items {
      setupInkRenderer(style: item.drawingStyle, preserveTexture: true)
      clearDrawingContext()
      draw(drawing: item.drawing, in: context)
      inkRenderer?.update()
    }
    
    finishDrawing()
  }
  
  public func getImage() -> CGImage? {
    let image = try? inkRenderer?.texture?.cgImage()
      return image
  }
  
  // MARK: - Setup
  private func setup() {
    addSubview(metalView)
    setupRenderState()
    setupInkRenderer(style: drawingStyle)
  }
    
  // MARK: - Draw context
  private func setupDrawingContext(_ size: CGSize) {
    let width = Int(size.width)
    let height = Int(size.height)
    
    let pixelRowAlignment = self.metalContext.device.minimumTextureBufferAlignment(for: .bgra8Unorm)
    let bytesPerRow = alignUp(size: 4 * width, align: pixelRowAlignment)
    
    let pagesize = Int(getpagesize())
    let allocationSize = alignUp(size: bytesPerRow * height, align: pagesize)
    var data: UnsafeMutableRawPointer? = nil
    let result = posix_memalign(&data, pagesize, allocationSize)
    if result != noErr {
      fatalError("Error during memory allocation")
    }
    
    let context = CGContext(data: data,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: bytesPerRow,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo:
                              CGBitmapInfo.byteOrder32Little.rawValue |
                            CGImageAlphaInfo.premultipliedFirst.rawValue)!
    
    context.scaleBy(x: 1.0, y: -1.0)
    context.translateBy(x: 0, y: -CGFloat(context.height))
    context.setLineJoin(.round)
    context.setLineCap(.round)
    context.setLineWidth(14)
    context.setStrokeColor(UIColor.yellow.cgColor)
    context.setFillColor(gray: 1.0, alpha: 1.0)
        
    let buffer = self.metalContext
      .device
      .makeBuffer(bytesNoCopy: context.data!,
                  length: allocationSize,
                  options: [.storageModeShared],
                  deallocator: { pointer, length in free(data) })!
    
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.width = context.width
    textureDescriptor.height = context.height
    textureDescriptor.storageMode = buffer.storageMode
    // we are only going to read from this texture on GPU side
    textureDescriptor.usage = .shaderRead
    
    self.drawingTexture = buffer.makeTexture(descriptor: textureDescriptor,
                                             offset: 0,
                                             bytesPerRow: context.bytesPerRow)
    self.drawingContext = context
    
  }
  

  // MARK: - Metal
  
  private func alignUp(size: Int, align: Int) -> Int {
    let alignmentMask = align - 1
    return (size + alignmentMask) & ~alignmentMask
  }
  
  private func setupRenderState() {
            
    let defaultLibrary = try! metalContext.library(for: .module)
    let fragment = defaultLibrary.makeFunction(name: "fragmentFunc")
    let vertex = defaultLibrary.makeFunction(name: "vertexFunc")
    
    let descriptor = MTLRenderPipelineDescriptor()
    
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm    
    descriptor.vertexFunction = vertex
    descriptor.fragmentFunction = fragment
    
    self.renderState = try! self.metalContext
      .device
      .makeRenderPipelineState(descriptor: descriptor)
  }
  
  private func resetImageTexture() {
    if let image = image?.cgImage {
      imageTexture = try? metalContext.texture(from: image, srgb: false, usage: [.shaderRead, .shaderWrite])
      
    } else {
      imageTexture = nil
    }
  }

  private func clearDrawingContext() {
    drawingContext.map { context in
      context.setFillColor(UIColor.clear.cgColor)
      context.clear(.init(x: 0, y: 0, width: context.width, height: context.height))
    }
  }
  
  private func setupInkRenderer(style: DrawingStyle?, preserveTexture: Bool = true) {
    guard
      let drawingStyle = style,
      let drawingContext = drawingContext
    else {
      inkRenderer = nil
      return
    }
    
    self.geometryTransform = TransformChain([
      TipTransformer(tip: drawingStyle.tipType == .arrow ? .arrow : .default)
    ])
    
    let prevTexture = inkRenderer?.texture
    let size = CGSize(width: drawingContext.width, height: drawingContext.height)
    switch drawingStyle.ink {
    case .draw:
      self.inkRenderer = try? DrawInk(context: metalContext, size: size)
    case .blur:
      self.inkRenderer = try? BlurInk(context: metalContext, size: size)
    case .erase:
      self.inkRenderer = try? EraseInk(context: metalContext, size: size, clearTexture: imageTexture)
    }
    
    if preserveTexture {
      inkRenderer?.setImage(prevTexture ?? imageTexture)
    } else {
      inkRenderer?.setImage(imageTexture)
    }
    inkRenderer?.setMask(drawingTexture)
    inkRenderer?.update()
  }
  
  private func handleLongPressDraw() {
    guard
      let currentDrawing = drawing,
      let context = drawingContext,
      let drawingStyle = drawingStyle
    else {
      return
    }
    
    if currentDrawing.pointsCount == 1 {
      let fill = Drawing(
        points: [
          .init(location: .init(x: 0, y: 0), time: 0, force: 0),
          .init(location: .init(x: context.width, y: 0), time: 0, force: 0),
          .init(location: .init(x: context.width, y: context.height), time: 0, force: 0),
          .init(location: .init(x: 0, y: context.height), time: 0, force: 0),
        ],
        color: UIColor(cgColor: drawingStyle.color).withAlphaComponent(1).cgColor,
        ink: .draw,
        strokeSize: 1,
        isClosed: true,
        isFilled: true
      )
      items.append(.init(drawingStyle: drawingStyle, drawing: fill))
      self.draw(drawing: fill, in: context)
      self.drawing = fill
      inkRenderer?.update()
      return
    }
    
    self.drawing = geometryTransform.transform(currentDrawing)
    self.drawing.map {
      draw(drawing: $0, in: context)
    }
    inkRenderer?.update()
  }
  
  private func finishDrawing() {
    moveDebouncedTask?.cancel()
    moveDebouncedTask = nil
    
    if
      let drawingStyle = drawingStyle,
      let transforming = transforming,
      let drawing = drawing {
      items.append(.init(
        drawingStyle: drawingStyle,
        drawing: transforming.transform(drawing)
      ))
    }
    drawing = nil
    transforming = nil

    clearDrawingContext()
    setupInkRenderer(style: drawingStyle)
    
    delegate?.canvasViewDidChanged(self)
  }
  
  // MARK: - Touches handling
  
  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard
      let context = drawingContext,
      let drawingStyle = drawingStyle else { return }
    
    moveDebouncedTask = DispatchQueue.main.asyncDeduped(target: self, after: 0.3) { [weak self] in
      self?.handleLongPressDraw()
      self?.finishDrawing()
    }
    
    self.transforming = drawingStyle.transforming
    
    let location = touches.first!.location(in: metalView)
    let normalizedLocation = CGPoint(x: location.x / metalView.bounds.width,
                                     y: location.y / metalView.bounds.height)
    let maskLocation = CGPoint(x: normalizedLocation.x * CGFloat(context.width),
                               y: normalizedLocation.y * CGFloat(context.height))
    timeStart = CACurrentMediaTime()
    
    drawing = .init(
      points: [
        .init(location: maskLocation, time: 0, force: 0)
      ],
      color: drawingStyle.color,
      ink: drawingStyle.ink,
      strokeSize: drawingStyle.strokeSize,
      isClosed: false,
      isFilled: false
    )
  }
  
  private var moveDebouncedTask: DispatchWorkItem?
  private var recentTouchLocation: CGPoint = .zero
  
  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard
      let context = drawingContext,
      let drawingStyle = drawingStyle,
      let transforming = transforming,
      let touch = touches.first,
      let allTouches = event?.coalescedTouches(for: touch) else {
      return
    }
    
    moveDebouncedTask = DispatchQueue.main.asyncDeduped(target: self, after: 0.3) { [weak self] in
      self?.handleLongPressDraw()
      self?.finishDrawing()
    }
    
    let curLocation = touch.location(in: metalView)
    let distance = recentTouchLocation.distance(to: curLocation)
    recentTouchLocation = curLocation
    
    let touches = distance > 1 ? allTouches : [touch]
    
    touches.forEach { touch in
      let location = touch.location(in: metalView)
      let normalizedLocation = CGPoint(x: location.x / metalView.bounds.width,
                                       y: location.y / metalView.bounds.height)
      let maskLocation = CGPoint(x: normalizedLocation.x * CGFloat(context.width),
                                 y: normalizedLocation.y * CGFloat(context.height))
      
      drawing?.append(point: .init(
        location: maskLocation,
        time: touch.timestamp - timeStart,
        force: 0
      ))
    }
            
    drawing.map { drawing in
      
      if drawing.pointsCount > 1000 {
        let transformedDrawing = transforming.transform(drawing)

        let splitDrawing = transformedDrawing.with(strokes: [
          transformedDrawing.strokes[0]
        ])
        items.append(.init(
          drawingStyle: drawingStyle,
          drawing: splitDrawing
        ))
        
        self.draw(drawing: splitDrawing, in: context)
        inkRenderer?.update()
        
        self.drawing = .init(
          points: drawing.strokes[0].points.suffix(50),
          color: drawingStyle.color,
          ink: drawingStyle.ink,
          strokeSize: drawingStyle.strokeSize,
          isClosed: false,
          isFilled: false
        )
        setupInkRenderer(style: drawingStyle)
      } else {
        draw(drawing: transforming.transform(drawing), in: context)
        inkRenderer?.update()
      }
    }
  }
  
  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    finishDrawing()
  }
  
  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    finishDrawing()
  }
    
  // MARK: - Drawing
  
  private func draw(drawing: Drawing, in context: CGContext) {
    context.setFillColor(UIColor.clear.cgColor)
    context.clear(.init(x: 0, y: 0, width: context.width, height: context.height))
    context.setFillColor(drawing.color)
    context.setStrokeColor(drawing.color)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setAllowsAntialiasing(true)
    drawing.strokes.forEach { stroke in
      draw(stroke: stroke, in: context)
    }
  }
  
  private func draw(stroke: Stroke, in context: CGContext) {
    guard
      let start = stroke.points.first
    else { return }
    
    context.setLineWidth(stroke.strokeSize)
    context.move(to: start.location)
    stroke.points.forEach({ point in
      context.addLine(to: point.location)
    })
    
    if stroke.isClosed {
      context.move(to: start.location)
      context.closePath()
    }

    if stroke.isFilled {
      context.fillPath()
    } else {
      context.strokePath()
    }
  }
  
}


// MARK: - MTKViewDelegate
extension CanvasView: MTKViewDelegate {
  public func draw(in view: MTKView) {
    try? self.metalContext.scheduleAndWait { buffer in
      buffer.render(descriptor: metalView.currentRenderPassDescriptor!) { encoder in
        encoder.setRenderPipelineState(self.renderState!)
        encoder.setFragmentTextures(
          inkRenderer?.texture
        )
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      }
      buffer.present(view.currentDrawable!)
    }
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    setupDrawingContext(size)
    setupInkRenderer(style: drawingStyle)
  }
}


extension CanvasView {
  struct Item {
    let drawingStyle: DrawingStyle
    let drawing: Drawing
  }
}
