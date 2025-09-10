import Foundation
import MetalKit
import Alloy

protocol InkRenderer: AnyObject {
  var texture: MTLTexture? { get }
  
  func setImage(_ texture: MTLTexture?)
  func setMask(_ texture: MTLTexture?)
  func update()
}

