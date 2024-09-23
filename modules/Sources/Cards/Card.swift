import Foundation

public struct Card: Equatable, Identifiable {
  public let id: UUID
  public let title: String
  public let description: String
  var isSolved: Bool = false
}
