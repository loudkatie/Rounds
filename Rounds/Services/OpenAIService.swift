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
    let newFactsLearned: [String]?
    let vitalValues: [String: Double]?
    let concerns: [String]?
    let patterns: [String]?
    let dayNumber: Int?  // Extract "day 5 post-transplant" → 5
    
    // Custom decoder to handle flexible JSON from GPT
    enum CodingKeys: String, CodingKey {
        case explanation
        case summaryPoints
        case followUpQuestions
        case newFactsLearned
        case vitalValues
        case concerns
        case patterns
        case dayNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields with fallbacks
        explanation = (try? container.decode(String.self, forKey: .explanation)) ?? ""
        summaryPoints = (try? container.decode([String].self, forKey: .summaryPoints)) ?? []
        followUpQuestions = (try? container.decode([String].self, forKey: .followUpQuestions)) ?? []
        
        // Optional fields
        newFactsLearned = try? container.decode([String].self, forKey: .newFactsLearned)
        concerns = try? container.decode([String].self, forKey: .concerns)
        patterns = try? container.decode([String].self, forKey: .patterns)
        dayNumber = try? container.decode(Int.self, forKey: .dayNumber)
        
        // vitalValues might come as [String: Double] or [String: Any] - handle flexibly
        if let vitals = try? container.decode([String: Double].self, forKey: .vitalValues) {
            vitalValues = vitals
        } else {
            vitalValues = nil
        }
    }
    
    init(explanation: String, summaryPoints: [String], followUpQuestions: [String],
         newFactsLearned: [String]?, vitalValues: [String: Double]?, concerns: [String]?, patterns: [String]?, dayNumber: Int?) {
        self.explanation = explanation
        self.summaryPoints = summaryPoints
        self.followUpQuestions = followUpQuestions
        self.newFactsLearned = newFactsLearned
        self.vitalValues = vitalValues
        self.concerns = concerns
        self.patterns = patterns
        self.dayNumber = dayNumber
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
        
        if let facts = analysis.newFactsLearned {
            memoryStore.learnFacts(facts)
            print("[Memory] Learned \(facts.count) new facts")
        }
        
        if let vitals = analysis.vitalValues {
            for (name, value) in vitals {
                memoryStore.recordVital(name, value: value)
            }
            print("[Memory] Recorded \(vitals.count) vital values")
        }
        
        if let patterns = analysis.patterns {
            for pattern in patterns {
                memoryStore.learnPattern(pattern)
            }
        }
        
        // Convert vital values to strings for session storage
        var medicalValuesStrings: [String: String] = [:]
        if let vitals = analysis.vitalValues {
            for (name, value) in vitals {
                medicalValuesStrings[name] = String(format: "%.2f", value)
            }
        }
        
        memoryStore.addSessionMemory(
            keyPoints: analysis.summaryPoints,
            medicalValues: medicalValuesStrings,
            concerns: analysis.concerns ?? [],
            dayNumber: analysis.dayNumber ?? memoryStore.memory.daysSinceSurgery
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

    // MARK: - Build Analysis Request (IMPROVED PROMPT)

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
        Analyze this medical conversation for \(caregiverName) who is caring for \(patientName).

        CRITICAL RULES:
        1. Write for a worried family member, NOT a medical professional.
        2. Explain ALL medical terms inline (e.g., "tacrolimus (an anti-rejection medication)").
        3. Focus on what's NEW today and what \(caregiverName) needs to understand.
        4. Be warm but VIGILANT - your job is to catch things a tired family member might miss.
        
        🔴🔴🔴 MULTI-DAY TREND ANALYSIS - THIS IS YOUR MOST IMPORTANT JOB:
        Look at the VITAL SIGN TRENDS above. For EACH value that has a concerning trend:
        
        1. ALWAYS REPORT THE FULL TRAJECTORY: "Creatinine started at 1.2 on Day 5, went to 1.5, then 1.8, now 1.9 - that's a 58% increase over 4 days"
        2. COMPARE TO BASELINE, NOT JUST YESTERDAY: The baseline (first reading) is the reference point
        3. USE PERCENTAGES: "Nearly doubled" or "increased 50%" hits harder than "went up a bit"
        4. CONNECT MULTIPLE DECLINING TRENDS: If creatinine is up AND oxygen needs are up AND temperature is up - SAY THIS IS A PATTERN
        
        🚨 URGENCY ESCALATION - MATCH YOUR TONE TO THE SEVERITY:
        - If ONE vital is slightly off → Note it calmly, suggest monitoring
        - If ONE vital has increased >25% from baseline → Flag it clearly with ⚠️
        - If MULTIPLE vitals are trending wrong → Use urgent language, this is a pattern
        - If patient going BACK to ICU, or REJECTION mentioned → This is MAJOR NEWS, lead with it
        - If oxygen needs are INCREASING (not weaning) → This is BACKWARDS PROGRESS, say so clearly
        
        🔍 MISSING INFORMATION DETECTION - CRITICAL:
        Compare what doctors SAID they would do vs what they mentioned today:
        - If they said "we'll check for rejection with the bronch" → Did they mention those results?
        - If they said "watching the effusion" → Did they say if it's better or worse?
        - If results are MISSING, your first follow-up question should ask about them!
        
        WRITING STYLE:
        - Keep sentences SHORT. Max 20 words per sentence.
        - Use PARAGRAPH BREAKS liberally - one idea per paragraph.
        - When reporting bad news, be CLEAR not clinical: "This is concerning" not "This warrants observation"
        - Bold **key terms** and **alarming findings**
        - If there's a clear "plan for today", make it a separate paragraph starting with "**Plan for Today:**"

        RESPOND IN PURE JSON (no markdown, no code blocks):

        {
            "explanation": "2-4 SHORT paragraphs. LEAD WITH THE MOST CONCERNING FINDING. Show full trajectories (X → Y → Z). Use urgent language when warranted. Include **Plan for Today:** section. Separate with \\n\\n.",
            
            "summaryPoints": [
                "MUST show FULL TREND with baseline: 'Creatinine: 1.2 → 1.5 → 1.8 → 1.9 (58% increase since Day 5) ⚠️'",
                "Flag concerning patterns: 'Multiple values trending wrong - kidney stress + increasing oxygen needs'",
                "Note MISSING info: 'Bronch results from yesterday not mentioned - ask about this'"
            ],
            
            "followUpQuestions": [
                "Ask about MISSING RESULTS that were expected (bronch cultures, biopsy results, lab tests mentioned previously)",
                "Specific question about the most concerning trend with context: 'The creatinine has gone from 1.2 to 1.9 over 4 days - what's causing this?'",
                "Connect multiple issues: 'With the kidney stress AND increasing oxygen needs, could this be rejection?'",
                "Ask about next steps: 'What would need to happen for Don to move back to a regular floor?'",
                "DO NOT use generic questions - every question should reference THIS patient's specific data or situation"
            ],
            
            "newFactsLearned": ["New info about \(patientName) to remember for future sessions"],
            
            "vitalValues": {
                "EXTRACT ALL NUMERIC VALUES FROM TRANSCRIPT": 0,
                "Creatinine": 1.5,
                "Tacrolimus": 10.2,
                "WhiteBloodCell": 8.2,
                "Temperature": 99.1,
                "OxygenLiters": 2,
                "OxygenSaturation": 94,
                "HeartRate": 72,
                "BloodPressureSystolic": 118,
                "BloodPressureDiastolic": 72,
                "ChestTubeOutput": 150
            },
            
            "concerns": ["Pattern concerns: What do MULTIPLE declining trends suggest?"],
            "patterns": ["Full trajectory assessment: baseline → current with % change"],
            "dayNumber": 5
        }
        
        IMPORTANT: For "dayNumber", extract the number from phrases like "day five post-transplant" → 5, "day 7" → 7. If no day is mentioned, use null.

        🚨 RED FLAG TRIGGERS - ESCALATE THESE IMMEDIATELY:
        - "A2 rejection" or any rejection → LEAD WITH THIS: "Don has been diagnosed with rejection"
        - "Back to ICU" → THIS IS MAJOR: "Don is being moved back to the ICU - this is an escalation"
        - Temperature >100 → FEVER: "Don had a fever overnight - this could indicate infection"
        - Creatinine increase >25% from baseline → KIDNEY STRESS: Show the full trajectory
        - Oxygen needs increasing (not weaning) → BACKWARD PROGRESS: "Don needed 2L, then 1L, now back to 3L - this is concerning"
        - Nephrology consult → KIDNEYS ARE WORRYING THEM
        - New antibiotics → INFECTION SUSPECTED
        - "Sats above 92" → STRUGGLING: They're having trouble keeping oxygen levels up
        
        PERSONALIZED ADVOCACY - YOU ARE \(patientName)'s CHAMPION:
        - Information gets lost between shifts. YOU remember EVERYTHING from every day.
        - If doctors minimize ("just a speed bump"), YOU translate: "They're moving him to ICU - this is serious even if they say it's precautionary"
        - You have CONTINUITY that the rotating medical staff doesn't have.
        - Your job is to help \(caregiverName) understand what's REALLY happening.
        """

        let userPrompt = """
        Here is today's transcript from \(patientName)'s medical appointment:

        ---
        \(transcript)
        ---
        
        Please analyze this and respond with ONLY the JSON object, no markdown formatting.
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
        
        You're answering a follow-up question about \(patientName)'s medical appointment today.
        
        Today's summary: \(previousExplanation.prefix(1500))
        
        RULES:
        - Keep responses SHORT and clear (3-5 sentences for simple questions)
        - Use bullet points only for lists of 3+ items
        - Explain medical terms in parentheses
        - Use \(patientName)'s name naturally
        - If you don't know something, say so honestly
        - Be warm and supportive
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

    // MARK: - Parse Analysis Response (SIMPLIFIED)

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

        print("[OpenAI] Raw response length: \(content.count) chars")
        print("[OpenAI] First 500 chars: \(String(content.prefix(500)))")
        
        // Parse JSON using JSONSerialization - simple and reliable
        guard let jsonData = content.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("[OpenAI] ❌ Failed to parse JSON")
            return createFallbackAnalysis(hint: "Could not parse AI response.")
        }
        
        print("[OpenAI] ✅ JSON parsed. Keys: \(dict.keys.sorted())")
        
        // Extract fields directly from dictionary
        let explanation = dict["explanation"] as? String ?? ""
        let summaryPoints = dict["summaryPoints"] as? [String] ?? []
        let followUpQuestions = dict["followUpQuestions"] as? [String] ?? []
        let newFactsLearned = dict["newFactsLearned"] as? [String]
        let concerns = dict["concerns"] as? [String]
        let patterns = dict["patterns"] as? [String]
        let dayNumber = dict["dayNumber"] as? Int
        
        // Handle vitalValues - might have null values
        var vitalValues: [String: Double]? = nil
        if let vitalsDict = dict["vitalValues"] as? [String: Any] {
            var cleanVitals: [String: Double] = [:]
            for (key, value) in vitalsDict {
                if let doubleVal = value as? Double {
                    cleanVitals[key] = doubleVal
                } else if let intVal = value as? Int {
                    cleanVitals[key] = Double(intVal)
                }
            }
            if !cleanVitals.isEmpty {
                vitalValues = cleanVitals
            }
        }
        
        // Validate we got real content
        if explanation.isEmpty {
            print("[OpenAI] ⚠️ Empty explanation in response")
            return createFallbackAnalysis(hint: "AI returned empty explanation.")
        }
        
        print("[OpenAI] ✅ Extracted explanation (\(explanation.count) chars), \(summaryPoints.count) points, \(followUpQuestions.count) questions")
        
        return ExtendedAnalysis(
            explanation: explanation,
            summaryPoints: summaryPoints.isEmpty ? ["See discussion above for key details"] : summaryPoints,
            followUpQuestions: followUpQuestions.isEmpty ? ["What other questions do you have about today's visit?"] : followUpQuestions,
            newFactsLearned: newFactsLearned,
            vitalValues: vitalValues,
            concerns: concerns,
            patterns: patterns,
            dayNumber: dayNumber
        )
    }
    
    // MARK: - Fallback Analysis
    
    private func createFallbackAnalysis(hint: String) -> ExtendedAnalysis {
        return ExtendedAnalysis(
            explanation: "We had trouble processing this recording. \(hint) Please try analyzing again.",
            summaryPoints: ["Analysis could not be completed - please retry"],
            followUpQuestions: ["Try recording again if analysis continues to fail"],
            newFactsLearned: nil,
            vitalValues: nil,
            concerns: nil,
            patterns: nil,
            dayNumber: nil
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
