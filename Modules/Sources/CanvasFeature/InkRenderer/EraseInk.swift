import Foundation
import MetalKit
import Alloy

public final class EraseInk: InkRenderer {
    
  private let context: MTLContext
  private let renderState: MTLRenderPipelineState
  private let offscreenRenderer: MTLOffscreenRenderer
  
  private var clearTexture: MTLTexture?
  private var maskTexture: MTLTexture?
  
  init(context: MTLContext, size: CGSize, clearTexture: MTLTexture?) throws {
    self.context = context
    self.clearTexture = clearTexture
    
    let defaultLibrary = try context.library(for: .module)
    let fragment = defaultLibrary.makeFunction(name: "fragmentErasingFunc")
    let vertex = defaultLibrary.makeFunction(name: "vertexFunc")
    
    let descriptor = MTLRenderPipelineDescriptor()
    
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.vertexFunction = vertex
    descriptor.fragmentFunction = fragment
    
    self.renderState = try context
      .device
      .makeRenderPipelineState(descriptor: descriptor)
    
    self.offscreenRenderer = try .new(
      in: context,
      width: Int(size.width),
      height: Int(size.height),
      pixelFormat: .bgra8Unorm,
      useDepthBuffer: false
    )
  }
  
  
  // MARK: - InkRenderer
  
  private(set) var texture: MTLTexture?
  
  func setImage(_ texture: MTLTexture?) {
    self.texture = texture
  }
  
  func setMask(_ texture: MTLTexture?) {
    self.maskTexture = texture
  }
  
  func update() {
    try? context.scheduleAndWait { buffer in
      offscreenRenderer.draw(in: buffer, drawCommands: { encoder in
        encoder.setRenderPipelineState(self.renderState)
        encoder.setFragmentTextures(
          clearTexture,
          texture,
          maskTexture
        )
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      })
    }
    texture = offscreenRenderer.texture
  }
}
