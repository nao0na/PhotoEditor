import UIKit

private struct RGBA {
  let r: CGFloat
  let g: CGFloat
  let b: CGFloat
  let a: CGFloat
}

private func rgba(from hex: String) -> RGBA? {
  let r, g, b, a: CGFloat
  let hasPrefix: Bool = hex.hasPrefix("#")
  let startIndex: String.Index = hex.index(
    hex.startIndex,
    offsetBy: hasPrefix ? 1 : 0
  )
  let hexColor: String = .init(hex[startIndex...])
  let count = hexColor.count
  let scanner: Scanner = .init(string: hexColor)
  var hexNumber: UInt64 = 0
  
  if count == 8, scanner.scanHexInt64(&hexNumber) {
    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
    a = CGFloat(hexNumber & 0x000000ff) / 255
    
    return RGBA(r: r, g: g, b: b, a: a)
  }
  
  if count == 6, scanner.scanHexInt64(&hexNumber) {
    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
    b = CGFloat(hexNumber & 0x0000ff) / 255
    a = 255
    
    return RGBA(r: r, g: g, b: b, a: a)
  }

  return nil
}

public extension UIColor {
  convenience init?(hex: String) {
    if let rgba = rgba(from: hex) {
      self.init(
        red: rgba.r,
        green: rgba.g,
        blue: rgba.b,
        alpha: rgba.a
      )
      return
    }

    return nil
  }

  convenience init?(hexP3: String) {
    if let rgba = rgba(from: hexP3) {
      self.init(
        displayP3Red: rgba.r,
        green: rgba.g,
        blue: rgba.b,
        alpha: rgba.a
      )
      return
    }

    return nil
  }
}
