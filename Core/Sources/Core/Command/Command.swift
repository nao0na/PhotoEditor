import Foundation

public typealias Command = CommandWith<Void>

extension CommandWith where T == Void {
  public func perform() {
    perform(with: ())
  }
}
