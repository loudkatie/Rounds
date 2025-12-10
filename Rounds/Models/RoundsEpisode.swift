import Foundation

struct RoundsEpisode: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var transcript: [TranscriptEntry]
    var summary: EpisodeSummary?

    init(id: UUID = UUID(), startTime: Date = Date()) {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
        self.transcript = []
        self.summary = nil
    }

    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var fullTranscriptText: String {
        transcript.map { $0.text }.joined(separator: " ")
    }
}

struct TranscriptEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let text: String
    let speaker: String?

    init(id: UUID = UUID(), timestamp: Date = Date(), text: String, speaker: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.speaker = speaker
    }
}

struct EpisodeSummary: Codable {
    let keyPoints: [String]
    let actionItems: [ActionItem]
    let participants: [String]
    let sentiment: String
    let topicsTags: [String]
}

struct ActionItem: Identifiable, Codable {
    let id: UUID
    let description: String
    let assignee: String?
    let dueDate: String?

    init(id: UUID = UUID(), description: String, assignee: String? = nil, dueDate: String? = nil) {
        self.id = id
        self.description = description
        self.assignee = assignee
        self.dueDate = dueDate
    }
}
