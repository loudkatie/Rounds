//
//  RoundsAnalysis.swift
//  Rounds
//
//  Model for OpenAI-generated transcript analysis.
//

import Foundation

struct FunctionalStatus: Codable, Equatable {
    let eating: String?
    let mobility: String?
    let mental: String?
    let overallTrend: String?
}

struct RoundsAnalysis: Codable, Equatable {
    // Core fields (always present)
    let explanation: String
    let summaryPoints: [String]
    let followUpQuestions: [String]
    
    // v0.3.1 additions (optional for backwards compatibility)
    let todayInOneWord: String?
    let uncertainties: [String]?
    let functionalStatus: FunctionalStatus?
    let newFactsLearned: [String]?
    let concerns: [String]?
    let patterns: [String]?
    let dayNumber: Int?

    static let empty = RoundsAnalysis(
        explanation: "",
        summaryPoints: [],
        followUpQuestions: [],
        todayInOneWord: nil,
        uncertainties: nil,
        functionalStatus: nil,
        newFactsLearned: nil,
        concerns: nil,
        patterns: nil,
        dayNumber: nil
    )
}
