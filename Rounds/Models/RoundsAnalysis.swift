//
//  RoundsAnalysis.swift
//  Rounds
//
//  Model for OpenAI-generated transcript analysis.
//

import Foundation

struct RoundsAnalysis: Codable, Equatable {
    let explanation: String
    let summaryPoints: [String]
    let followUpQuestions: [String]

    static let empty = RoundsAnalysis(
        explanation: "",
        summaryPoints: [],
        followUpQuestions: []
    )
}
