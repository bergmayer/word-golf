//
//  DifficultyLevel.swift
//  WordGolfCore
//
//  Difficulty level settings for Word Golf
//

import Foundation

public enum DifficultyLevel: Int, CaseIterable, Identifiable, Sendable {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case unlimited = 100

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .unlimited: return "Unlimited"
        default: return "\(rawValue) Steps"
        }
    }
}
