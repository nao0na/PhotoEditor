import Foundation

public extension NSObjectProtocol {
  @discardableResult
  func apply(_ closure: (Self) -> Void) -> Self {
    closure(self)
    return self
  }
}
