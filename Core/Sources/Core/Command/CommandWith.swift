import Foundation

public final class CommandWith<T> {
  // MARK: - Properties

  private let id: String
  private let action: (T) -> ()
  private let file: StaticString
  private let function: StaticString
  private let line: Int

  public static var nop: CommandWith {
    return CommandWith { _ in }
  }

  // MARK: - init/deinit

  public init(
    id: String = "<unknown>",
    action: @escaping (T) -> (),
    file: StaticString = #file,
    function: StaticString = #function,
    line: Int = #line
  ) {
    self.id = id
    self.action = action
    self.file = file
    self.function = function
    self.line = line
  }

  // MARK: - Public methods

  public func perform(with value: T) {
    action(value)
  }

  public func map<U>(transform: @escaping (U) -> T) -> CommandWith<U> {
    return CommandWith<U> { u in
      self.perform(with: transform(u))
    }
  }

  public func dispatchedAsync(on queue: DispatchQueue) -> CommandWith {
    return CommandWith { value in
      queue.async {
        self.perform(with: value)
      }
    }
  }

  public func dispatchedSync(on queue: DispatchQueue) -> CommandWith {
    return CommandWith { value in
      queue.sync {
        self.perform(with: value)
      }
    }
  }

  @objc public func debugQuickLookObject() -> AnyObject? {
    return """
    type: \(String(describing: type(of: self)))
    id: \(id)
    file: \(file)
    function: \(function)
    line: \(line)
    """ as NSString
  }
}

// MARK: - Hashable

extension CommandWith: Hashable {
  public static func ==(left: CommandWith, right: CommandWith) -> Bool {
    return ObjectIdentifier(left) == ObjectIdentifier(right)
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

// MARK: - CustomStringConvertible

extension CommandWith: CustomStringConvertible {
  public var description: String {
    return """
    type: \(String(describing: type(of: self)))
    id: \(id)
    file: \(file)
    function: \(function)
    line: \(line)
    """
  }
}

// MARK: - CustomDebugStringConvertible

extension CommandWith: CustomDebugStringConvertible {
  public var debugDescription: String {
    return """
    type: \(String(describing: type(of: self)))
    id: \(id)
    file: \(file)
    function: \(function)
    line: \(line)
    """
  }
}
