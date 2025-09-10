import Foundation
import MetalKit
import Alloy

public final class BlurInk: InkRenderer {
    
  private let context: MTLContext
  private let renderState: MTLRenderPipelineState
  private let offscreenRenderer: MTLOffscreenRenderer
  private let blurShader: MPSImageGaussianBlur
  
  private var maskTexture: MTLTexture?
  private var blurTexture: MTLTexture?
  
  init(context: MTLContext, size: CGSize, radius: Float = 12.0) throws {
    self.context = context
    
    let defaultLibrary = try context.library(for: .module)
    let fragment = defaultLibrary.makeFunction(name: "fragmentBlurringFunc")
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
    
    self.blurShader = MPSImageGaussianBlur(
      device: context.device,
      sigma: radius
    )
  }
  
  
  // MARK: - InkRenderer
  
  private(set) var texture: MTLTexture?
  
  func setImage(_ texture: MTLTexture?) {
    self.texture = texture
    texture.map {
      self.blurTexture = try? self.makeBlur($0)
    }
  }
  
  func setMask(_ texture: MTLTexture?) {
    self.maskTexture = texture
  }
  
  func update() {
    try? context.scheduleAndWait { buffer in
      offscreenRenderer.draw(in: buffer, drawCommands: { encoder in
        encoder.setRenderPipelineState(self.renderState)
        encoder.setFragmentTextures(
          texture,
          blurTexture,
          maskTexture
        )
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      })
    }
    texture = offscreenRenderer.texture
  }
  
  private func makeBlur(_ texture: MTLTexture) throws -> MTLTexture? {
    let blurTexture = try texture.matchingTexture(usage: [.shaderRead, .shaderWrite])
    
    try context.scheduleAndWait { buffer in
      blurShader.encode(commandBuffer: buffer,
                        sourceTexture: texture,
                        destinationTexture: blurTexture)
    }
    return blurTexture
  }
}
