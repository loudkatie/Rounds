//
//  OpenAIService.swift
//  Rounds
//
//  Calls OpenAI's Chat Completions API to analyze medical transcripts.
//  Uses GPT-4o-mini for cost efficiency (~$0.15/1M input tokens).
//
//  KEY: Injects user profile context so AI knows the patient and doesn't
//  re-explain who they are or their baseline condition.
//

import Foundation

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case requestFailed(String)
    case emptyResponse
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured."
        case .invalidURL:
            return "Invalid API endpoint."
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .emptyResponse:
            return "No response received."
        case .rateLimited:
            return "Rate limited. Try again in a moment."
        case .serverError(let code):
            return "Server error (\(code)). Try again."
        }
    }
}

@MainActor
final class OpenAIService: ObservableObject {
    static let shared = OpenAIService()

    @Published private(set) var isAnalyzing = false

    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"

    private init() {}

    // MARK: - API Key Management

    private var apiKey: String? {
        // Priority 1: Environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        // Priority 2: Config.plist in bundle
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: configPath),
           let key = config["OPENAI_API_KEY"] as? String, !key.isEmpty {
            return key
        }

        return nil
    }
    
    // MARK: - Profile Context
    
    private var profileContext: String {
        let profile = ProfileStore.shared
        
        guard profile.hasCompletedOnboarding,
              let currentProfile = profile.currentProfile else {
            return ""
        }
        
        var context = """
        IMPORTANT CONTEXT - You already know this, do NOT re-explain it:
        - Caregiver's name: \(currentProfile.caregiverName)
        - Patient's name: \(currentProfile.patientName)
        - Patient's situation: \(currentProfile.patientSituation)
        """
        
        // Add memory context if available
        let memory = currentProfile.aiMemory
        
        if !memory.keyMedicalFacts.isEmpty {
            context += "\n- Key medical facts: \(memory.keyMedicalFacts.joined(separator: "; "))"
        }
        
        if !memory.currentMedications.isEmpty {
            context += "\n- Current medications: \(memory.currentMedications.joined(separator: ", "))"
        }
        
        if !memory.careTeamMembers.isEmpty {
            context += "\n- Care team: \(memory.careTeamMembers.joined(separator: ", "))"
        }
        
        if !memory.ongoingConcerns.isEmpty {
            context += "\n- Ongoing concerns being monitored: \(memory.ongoingConcerns.joined(separator: "; "))"
        }
        
        return context
    }

    // MARK: - Transcript Analysis

    func analyzeTranscript(_ transcript: String) async throws -> RoundsAnalysis {
        guard let apiKey = apiKey else {
            throw OpenAIError.missingAPIKey
        }

        guard let url = URL(string: endpoint) else {
            throw OpenAIError.invalidURL
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        print("[OpenAI] Sending transcript for analysis (\(transcript.count) chars)")

        let request = buildRequest(url: url, apiKey: apiKey, transcript: transcript)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.requestFailed("Invalid response type")
        }

        print("[OpenAI] Response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data)
        case 429:
            throw OpenAIError.rateLimited
        case 500...599:
            throw OpenAIError.serverError(httpResponse.statusCode)
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[OpenAI] Error: \(errorMessage)")
            throw OpenAIError.requestFailed(errorMessage)
        }
    }

    // MARK: - Follow-up Questions

    func askFollowUp(
        question: String,
        transcript: String,
        previousExplanation: String,
        conversationHistory: [ConversationMessage]
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw OpenAIError.missingAPIKey
        }

        guard let url = URL(string: endpoint) else {
            throw OpenAIError.invalidURL
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        print("[OpenAI] Sending follow-up question")

        let request = buildFollowUpRequest(
            url: url,
            apiKey: apiKey,
            question: question,
            transcript: transcript,
            previousExplanation: previousExplanation,
            conversationHistory: conversationHistory
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.requestFailed("Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200:
            return try parseFollowUpResponse(data)
        case 429:
            throw OpenAIError.rateLimited
        case 500...599:
            throw OpenAIError.serverError(httpResponse.statusCode)
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.requestFailed(errorMessage)
        }
    }

    private func buildFollowUpRequest(
        url: URL,
        apiKey: String,
        question: String,
        transcript: String,
        previousExplanation: String,
        conversationHistory: [ConversationMessage]
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let patientName = ProfileStore.shared.patientName

        let systemPrompt = """
        You are Rounds AI, a calm and knowledgeable medical interpreter. You're like a friend who went to med school — you explain things clearly without being condescending.

        \(profileContext)

        You already know \(patientName) and their situation well. Do NOT re-introduce them or explain their baseline condition — the caregiver already knows all of this.

        Context from this session:
        - Original transcript: \(transcript.prefix(2000))...
        - Your previous explanation: \(previousExplanation.prefix(1000))...

        FORMATTING RULES (CRITICAL):
        - Keep responses SHORT (3-5 sentences max for simple questions)
        - Use bullet points for lists or multiple items
        - Add a blank line between paragraphs for readability
        - If suggesting questions to ask, format as a numbered list
        - Bold key terms by wrapping in **asterisks**
        
        Be warm and reassuring. If you don't know something or if they should ask their doctor, say so honestly. Use \(patientName)'s name naturally.
        """

        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]

        // Add conversation history (limited to last 4 messages to save tokens)
        for message in conversationHistory.suffix(4) {
            messages.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ])
        }

        // Add the new question
        messages.append(["role": "user", "content": question])

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 800
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseFollowUpResponse(_ data: Data) throws -> String {
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content, !content.isEmpty else {
            throw OpenAIError.emptyResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Request Building

    private func buildRequest(url: URL, apiKey: String, transcript: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let patientName = ProfileStore.shared.patientName

        let systemPrompt = """
        You are Rounds AI. You're like a friend who went to med school — you translate complex medical conversations into clear, respectful language for educated adults. You're warm, calm, and never condescending.

        \(profileContext)

        CRITICAL RULES:
        1. You already know \(patientName) and their medical situation. Do NOT re-introduce them or explain their baseline condition — the caregiver already knows all of this intimately.
        2. Focus ONLY on what's NEW in today's conversation — what changed, what was decided, what to watch for.
        3. Your suggested questions must be SPECIFIC to THIS conversation, not generic questions about the disease. The caregiver is already an expert on the disease — they need help with TODAY's decisions.

        When given a transcript, provide:

        1. **WHAT THEY DISCUSSED**: A clear 2-3 paragraph translation of what the medical team said TODAY. Focus on: decisions made, changes to treatment, things being monitored, timeline updates. Use \(patientName)'s name naturally.

        2. **KEY POINTS**: 3-5 bullet points of the most important takeaways from THIS session. Be specific to what was discussed.

        3. **QUESTIONS TO CONSIDER**: 3-5 follow-up questions the caregiver could ask. These MUST be:
           - Specific to what was discussed in THIS transcript
           - Based on the actual data/decisions mentioned
           - NOT generic disease questions (they can Google those)
           - Actionable for the next conversation with doctors
           
           Example of a GOOD question: "The team mentioned \(patientName)'s tacrolimus level is at 11.2 — if it trends higher tomorrow, what adjustments might they consider?"
           Example of a BAD question: "What is tacrolimus used for?" (too generic, they already know this)
        """

        let userPrompt = """
        Please analyze this medical conversation transcript from today's rounds:

        ---
        \(transcript)
        ---
        
        Remember: Focus on what's NEW today. Don't re-explain who \(patientName) is or their baseline situation.
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1500
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Response Parsing

    private func parseResponse(_ data: Data) throws -> RoundsAnalysis {
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content, !content.isEmpty else {
            throw OpenAIError.emptyResponse
        }

        print("[OpenAI] Received response (\(content.count) chars)")

        // Parse the markdown-style response into structured data
        return parseMarkdownResponse(content)
    }

    private func parseMarkdownResponse(_ content: String) -> RoundsAnalysis {
        var explanation = ""
        var keyPoints: [String] = []
        var questions: [String] = []

        // Split by section headers
        let lines = content.components(separatedBy: "\n")
        var currentSection = "explanation"

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Detect section headers
            let lowerLine = trimmedLine.lowercased()
            if lowerLine.contains("key point") || lowerLine.contains("key concern") || lowerLine.contains("takeaway") {
                currentSection = "keypoints"
                continue
            } else if lowerLine.contains("question") || lowerLine.contains("ask your") || lowerLine.contains("follow-up") || lowerLine.contains("follow up") || lowerLine.contains("to consider") {
                currentSection = "questions"
                continue
            } else if lowerLine.contains("what they discussed") || lowerLine.contains("explanation") || lowerLine.contains("what this means") || lowerLine.contains("summary") {
                currentSection = "explanation"
                continue
            }

            // Skip empty lines and header markers
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("##") || trimmedLine.hasPrefix("**") && trimmedLine.hasSuffix("**") && trimmedLine.count < 50 {
                continue
            }

            // Extract bullet points
            let bulletPattern = /^[-•*\d.]+\s*/
            let cleanedLine = trimmedLine.replacing(bulletPattern, with: "")

            switch currentSection {
            case "keypoints":
                if !cleanedLine.isEmpty {
                    keyPoints.append(cleanedLine)
                }
            case "questions":
                if !cleanedLine.isEmpty {
                    questions.append(cleanedLine)
                }
            default:
                if !cleanedLine.isEmpty {
                    explanation += (explanation.isEmpty ? "" : " ") + cleanedLine
                }
            }
        }

        // Fallback if parsing didn't find sections
        if explanation.isEmpty && keyPoints.isEmpty && questions.isEmpty {
            explanation = content
            keyPoints = ["Review the explanation above for details"]
            questions = ["What are the next steps?", "When should I schedule a follow-up?", "Are there any warning signs I should watch for?"]
        }

        // Ensure we have at least some content in each section
        if keyPoints.isEmpty {
            keyPoints = ["See explanation above"]
        }
        if questions.isEmpty {
            questions = ["What questions do you have for me?", "What are the next steps?"]
        }

        return RoundsAnalysis(
            explanation: explanation,
            summaryPoints: Array(keyPoints.prefix(5)),
            followUpQuestions: Array(questions.prefix(5))
        )
    }
}
