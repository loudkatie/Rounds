//
//  RoundsAnalysis.swift
//  Rounds
//
//  Model for OpenAI-generated transcript analysis.
//

import Foundation

struct FunctionalStatus: Codable, Equatable {
    var eating: String?
    var mobility: String?
    var mental: String?
    var overallTrend: String?
}

struct RoundsAnalysis: Codable, Equatable {
    // Core fields (always present)
    let explanation: String
    let summaryPoints: [String]
    let followUpQuestions: [String]
    
    // v0.3.1 additions (optional with defaults for backwards compatibility)
    var todayInOneWord: String? = nil
    var uncertainties: [String]? = nil
    var functionalStatus: FunctionalStatus? = nil
    var newFactsLearned: [String]? = nil
    var concerns: [String]? = nil
    var patterns: [String]? = nil
    var dayNumber: Int? = nil

    static let empty = RoundsAnalysis(
        explanation: "",
        summaryPoints: [],
        followUpQuestions: []
    )
}
