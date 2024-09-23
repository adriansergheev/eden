import Foundation
import CasePaths

public struct Card: Equatable, Identifiable {
  @CasePathable
  @dynamicMemberLookup
  public enum Status: Equatable {
    case solved(Bool)
    case upcoming
  }
  public let id: UUID
  public let title: String
  public let description: String
  public var status: Status
}

extension Card {
  public var isSolved: Bool {
    if case .solved(let isSolved) = status {
      return isSolved
    }
    return false
  }
}
