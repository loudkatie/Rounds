//
//  RecordingSession.swift
//  Rounds AI
//
//  Persisted recording session with transcript and AI analysis.
//

import Foundation

struct RecordingSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var transcript: String  // Mutable for session chaining (append mode)
    var durationSeconds: Int  // Mutable for session chaining
    var aiExplanation: String?
    var keyPoints: [String]
    var followUpQuestions: [String]
    var conversationHistory: [ConversationMessage]
    var analysis: RoundsAnalysis?

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        transcript: String,
        durationSeconds: Int,
        aiExplanation: String? = nil,
        keyPoints: [String] = [],
        followUpQuestions: [String] = [],
        conversationHistory: [ConversationMessage] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.transcript = transcript
        self.durationSeconds = durationSeconds
        self.aiExplanation = aiExplanation
        self.keyPoints = keyPoints
        self.followUpQuestions = followUpQuestions
        self.conversationHistory = conversationHistory
    }
    
    // Alias for backwards compatibility
    var date: Date { startTime }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var shareableText: String {
        var text = "Rounds AI Summary – \(formattedDate)\n\n"

        if let explanation = aiExplanation, !explanation.isEmpty {
            text += "What This Means:\n\(explanation)\n\n"
        }

        if !keyPoints.isEmpty {
            text += "Key Points:\n"
            for point in keyPoints {
                text += "• \(point)\n"
            }
            text += "\n"
        }

        if !followUpQuestions.isEmpty {
            text += "Questions to Ask:\n"
            for (index, question) in followUpQuestions.enumerated() {
                text += "\(index + 1). \(question)\n"
            }
        }

        return text
    }
}

struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let isUser: Bool
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), isUser: Bool, content: String, timestamp: Date = Date()) {
        self.id = id
        self.isUser = isUser
        self.content = content
        self.timestamp = timestamp
    }
}
