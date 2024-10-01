import Foundation
import CasePaths

public struct Card: Equatable, Identifiable {
  @CasePathable
  @dynamicMemberLookup
  public enum Status: Equatable {
    case solved(Bool)
    case upcoming
  }

  public enum Target: Equatable {
    case screenTime
    case tutorial
  }

  public let id: UUID
  public let title: String
  public let description: String
  public let target: Target
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
