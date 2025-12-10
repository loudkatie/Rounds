import Foundation

final class LlamaAgentService {
    static let shared = LlamaAgentService()

    private init() {}

    /// Stub: Generates a mock summary from transcript text
    /// TODO: Replace with actual Llama API call
    func generateSummary(from transcript: String) async throws -> EpisodeSummary {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Return mock summary
        return EpisodeSummary(
            keyPoints: [
                "Discussed project timeline and deliverables",
                "Reviewed Q4 budget allocation",
                "Agreed on next steps for product launch"
            ],
            actionItems: [
                ActionItem(
                    description: "Finalize design mockups by end of week",
                    assignee: "Design Team",
                    dueDate: "Friday"
                ),
                ActionItem(
                    description: "Schedule follow-up meeting with stakeholders",
                    assignee: "Project Lead",
                    dueDate: "Next Monday"
                ),
                ActionItem(
                    description: "Send updated requirements document",
                    assignee: nil,
                    dueDate: "Tomorrow"
                )
            ],
            participants: ["Speaker 1", "Speaker 2"],
            sentiment: "Productive and collaborative",
            topicsTags: ["project-planning", "budget", "product-launch"]
        )
    }

    /// Stub: Processes transcript for real-time insights
    /// TODO: Replace with actual streaming Llama call
    func processRealTimeInsight(transcript: String) async throws -> String {
        // Simulate processing
        try await Task.sleep(nanoseconds: 500_000_000)
        return "Consider asking about timeline specifics"
    }
}
