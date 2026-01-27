//
//  OpenAIService.swift
//  Rounds AI
//
//  Calls OpenAI's Chat Completions API to analyze medical transcripts.
//  Uses GPT-4o-mini for cost efficiency (~$0.15/1M input tokens).
//
//  KEY FEATURE: Injects full patient memory context so GPT "remembers"
//  everything about this patient across all sessions.
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

// MARK: - Extended Analysis Response (includes learning)

struct ExtendedAnalysis: Codable {
    let explanation: String
    let summaryPoints: [String]
    let followUpQuestions: [String]
    let newFactsLearned: [String]?  // Facts to remember for next time
    let vitalValues: [String: Double]?  // Extracted vitals: "Creatinine": 1.4
    let concerns: [String]?  // New concerns identified
    let patterns: [String]?  // Patterns observed across sessions
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
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: configPath),
           let key = config["OPENAI_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        return nil
    }

    // MARK: - Transcript Analysis (with Memory)

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

        // Get the full memory context
        let memoryStore = AIMemoryStore.shared
        let memoryContext = memoryStore.memory.buildSystemContext()
        
        let request = buildAnalysisRequest(
            url: url,
            apiKey: apiKey,
            transcript: transcript,
            memoryContext: memoryContext
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.requestFailed("Invalid response type")
        }

        print("[OpenAI] Response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200:
            let analysis = try parseAnalysisResponse(data)
            
            // LEARNING LOOP: Save what GPT learned back to memory
            await saveLearnedKnowledge(from: analysis)
            
            return RoundsAnalysis(
                explanation: analysis.explanation,
                summaryPoints: analysis.summaryPoints,
                followUpQuestions: analysis.followUpQuestions
            )
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
    
    // MARK: - Save Learned Knowledge
    
    private func saveLearnedKnowledge(from analysis: ExtendedAnalysis) async {
        let memoryStore = AIMemoryStore.shared
        
        // Save new facts
        if let facts = analysis.newFactsLearned {
            memoryStore.learnFacts(facts)
            print("[Memory] Learned \(facts.count) new facts")
        }
        
        // Save vital values
        if let vitals = analysis.vitalValues {
            for (name, value) in vitals {
                memoryStore.recordVital(name, value: value)
            }
            print("[Memory] Recorded \(vitals.count) vital values")
        }
        
        // Save patterns
        if let patterns = analysis.patterns {
            for pattern in patterns {
                memoryStore.learnPattern(pattern)
            }
        }
        
        // Save session summary
        memoryStore.addSessionMemory(
            keyPoints: analysis.summaryPoints,
            concerns: analysis.concerns ?? [],
            dayNumber: memoryStore.memory.daysSinceSurgery
        )
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

        // Record the question in memory
        AIMemoryStore.shared.memory.recordQuestion(question)
        AIMemoryStore.shared.save()

        let memoryContext = AIMemoryStore.shared.memory.buildSystemContext()
        
        let request = buildFollowUpRequest(
            url: url,
            apiKey: apiKey,
            question: question,
            transcript: transcript,
            previousExplanation: previousExplanation,
            conversationHistory: conversationHistory,
            memoryContext: memoryContext
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

    // MARK: - Build Analysis Request

    private func buildAnalysisRequest(
        url: URL,
        apiKey: String,
        transcript: String,
        memoryContext: String
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        
        let patientName = AIMemoryStore.shared.memory.patientName
        let caregiverName = AIMemoryStore.shared.memory.caregiverName

        let systemPrompt = """
        \(memoryContext)
        
        TODAY'S TASK:
        Analyze the transcript from today's medical conversation. You already know \(patientName) well from previous sessions.

        CRITICAL RULES:
        1. Do NOT re-introduce \(patientName) or explain their baseline condition — \(caregiverName) knows all of this.
        2. Focus ONLY on what's NEW today — changes, decisions, things to watch.
        3. Suggested questions must be SPECIFIC to THIS conversation, not generic.
        4. Explain medical terms inline at a 12th-grade reading level.

        RESPOND IN THIS JSON FORMAT:
        {
            "explanation": "2-3 paragraphs about what was discussed TODAY. Use \\n\\n between paragraphs.",
            "summaryPoints": ["Key point 1", "Key point 2", ...],
            "followUpQuestions": ["Specific question about today's discussion", ...],
            "newFactsLearned": ["Any new medical facts to remember for future sessions"],
            "vitalValues": {"Creatinine": 1.4, "Tacrolimus": 11.2},
            "concerns": ["New concerns identified"],
            "patterns": ["Any patterns you notice across sessions"]
        }
        
        For vitalValues, only include numeric values mentioned (lab results, vitals, etc).
        For newFactsLearned, include facts that would be useful to know in future sessions.
        For patterns, note any trends you see (improving, worsening, etc).
        """

        let userPrompt = """
        Today's transcript:

        \(transcript)
        
        Analyze this and respond with the JSON format specified.
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2000,
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Build Follow-up Request

    private func buildFollowUpRequest(
        url: URL,
        apiKey: String,
        question: String,
        transcript: String,
        previousExplanation: String,
        conversationHistory: [ConversationMessage],
        memoryContext: String
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let patientName = AIMemoryStore.shared.memory.patientName

        let systemPrompt = """
        \(memoryContext)
        
        You're answering a follow-up question about today's session.
        
        Today's transcript summary: \(previousExplanation.prefix(1500))
        
        RULES:
        - Keep responses SHORT (3-5 sentences for simple questions)
        - Use bullet points for lists
        - Add blank lines between paragraphs
        - Bold key terms with **asterisks**
        - Use \(patientName)'s name naturally
        - If you don't know, say so honestly
        """

        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]

        for message in conversationHistory.suffix(6) {
            messages.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ])
        }

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

    // MARK: - Parse Analysis Response

    private func parseAnalysisResponse(_ data: Data) throws -> ExtendedAnalysis {
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
        
        // Parse JSON response
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.requestFailed("Invalid JSON encoding")
        }
        
        do {
            let analysis = try JSONDecoder().decode(ExtendedAnalysis.self, from: jsonData)
            return analysis
        } catch {
            print("[OpenAI] JSON parse error: \(error). Falling back to text parsing.")
            // Fallback to text parsing if JSON fails
            return fallbackParseResponse(content)
        }
    }
    
    private func fallbackParseResponse(_ content: String) -> ExtendedAnalysis {
        // Simple fallback parser
        return ExtendedAnalysis(
            explanation: content,
            summaryPoints: ["See explanation above for details"],
            followUpQuestions: ["What questions do you have?"],
            newFactsLearned: nil,
            vitalValues: nil,
            concerns: nil,
            patterns: nil
        )
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
}
