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
    let dayNumber: Int?
    // v0.3.1 additions
    let todayInOneWord: String?
    let uncertainties: [String]?
    let functionalStatus: FunctionalStatus?
    
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
        case todayInOneWord
        case uncertainties
        case functionalStatus
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
        todayInOneWord = try? container.decode(String.self, forKey: .todayInOneWord)
        uncertainties = try? container.decode([String].self, forKey: .uncertainties)
        functionalStatus = try? container.decode(FunctionalStatus.self, forKey: .functionalStatus)
        
        // vitalValues might come as [String: Double] or [String: Any] - handle flexibly
        if let vitals = try? container.decode([String: Double].self, forKey: .vitalValues) {
            vitalValues = vitals
        } else {
            vitalValues = nil
        }
    }
    
    init(explanation: String, summaryPoints: [String], followUpQuestions: [String],
         newFactsLearned: [String]?, vitalValues: [String: Double]?, concerns: [String]?, 
         patterns: [String]?, dayNumber: Int?, todayInOneWord: String? = nil, 
         uncertainties: [String]? = nil, functionalStatus: FunctionalStatus? = nil) {
        self.explanation = explanation
        self.summaryPoints = summaryPoints
        self.followUpQuestions = followUpQuestions
        self.newFactsLearned = newFactsLearned
        self.vitalValues = vitalValues
        self.concerns = concerns
        self.patterns = patterns
        self.dayNumber = dayNumber
        self.todayInOneWord = todayInOneWord
        self.uncertainties = uncertainties
        self.functionalStatus = functionalStatus
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
                followUpQuestions: analysis.followUpQuestions,
                todayInOneWord: analysis.todayInOneWord,
                uncertainties: analysis.uncertainties,
                functionalStatus: analysis.functionalStatus,
                newFactsLearned: analysis.newFactsLearned,
                concerns: analysis.concerns,
                patterns: analysis.patterns,
                dayNumber: analysis.dayNumber
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
        
        YOU ARE ROUNDS AI — \(patientName)'s ADVOCATE AND \(caregiverName)'s TRUSTED COMPANION.
        
        You remember EVERYTHING from every session. You have continuity that rotating medical staff don't have. Your job is to help \(caregiverName) truly understand what's happening with \(patientName).

        ═══════════════════════════════════════════════════════════════
        STEP 1: THINK BEFORE YOU WRITE (Do this mentally, don't output)
        ═══════════════════════════════════════════════════════════════
        
        A) EXTRACT from today's transcript:
           - New diagnoses or findings
           - Test/procedure results given
           - Tests mentioned but results NOT given
           - Medications discussed (new, changed, or stopped)
           - Any numbers: vitals, lab values, dosages
        
        B) COMPARE TO MEMORY - What's different from before?
           - Values that changed (and direction: better/worse)
           - Things doctors previously said they'd do — were they mentioned today?
           - New concerns that weren't present before
        
        C) NOTICE FUNCTIONAL STATUS (often the earliest warning sign):
           - Eating/appetite: improving, declining, or not mentioned?
           - Activity/mobility: doing PT? walking? weaker?
           - Mental status: alert? confused? sleepy? agitated?
           - Energy level: mentioned?
        
        D) PRIORITIZE - Rank by what \(caregiverName) NEEDS to know:
           1. [Most urgent: new diagnosis? emergency? major change?]
           2. [Second most important]
           3. [Third]
        
        NOW write your response, leading with #1.

        ═══════════════════════════════════════════════════════════════
        STEP 2: MULTI-DAY TREND ANALYSIS
        ═══════════════════════════════════════════════════════════════
        
        Look at VITAL SIGN TRENDS from memory. For values with concerning trends:
        
        1. SHOW THE FULL TRAJECTORY: "Creatinine started at 1.2, went to 1.5, then 1.8, now 1.9"
        2. COMPARE TO BASELINE (first reading), not just yesterday
        3. USE PERCENTAGES: "increased 58%" hits harder than "went up"
        4. CONNECT MULTIPLE TRENDS: If several values are going wrong together — SAY IT'S A PATTERN
        
        ═══════════════════════════════════════════════════════════════
        STEP 3: URGENCY ESCALATION
        ═══════════════════════════════════════════════════════════════
        
        Match your tone to severity:
        - ONE value slightly off → Note calmly, suggest monitoring
        - ONE value changed significantly (>25%) → Flag clearly with ⚠️
        - MULTIPLE values trending wrong → Urgent language, call it a pattern
        - ICU transfer, major diagnosis, emergency → THIS IS MAJOR NEWS, lead with it
        - Patient going BACKWARDS (more oxygen, worse mobility) → Say so clearly
        
        ═══════════════════════════════════════════════════════════════
        STEP 4: DETECT WHAT'S MISSING
        ═══════════════════════════════════════════════════════════════
        
        Compare what doctors SAID they would do vs what they mentioned today:
        - "We'll check the cultures" → Were results discussed?
        - "Watching the [X]" → Did they say if it's better or worse?
        - If results are MISSING, your first follow-up question asks about them.
        
        ═══════════════════════════════════════════════════════════════
        STEP 5: CUT THROUGH MINIMIZATION
        ═══════════════════════════════════════════════════════════════
        
        If doctors use softening language like:
        - "Just a little speed bump" / "Minor setback"
        - "Nothing to worry about" / "Being extra careful"
        - "Precautionary measure"
        
        ...but the FACTS suggest escalation (ICU transfer, new specialists called, new medications), note this: "They're describing this as routine, but [specific fact] suggests they're taking it seriously."
        
        ═══════════════════════════════════════════════════════════════
        WRITING RULES
        ═══════════════════════════════════════════════════════════════
        
        - Write for a worried family member, NOT a medical professional
        - Explain medical terms inline: "tacrolimus (an anti-rejection medication)"
        - Keep sentences SHORT — max 20 words
        - Use PARAGRAPH BREAKS — one idea per paragraph
        - Be CLEAR not clinical: "This is concerning" not "This warrants observation"
        - If there's a plan, write it as a separate paragraph: "Next Steps: [plan]"

        ═══════════════════════════════════════════════════════════════
        JSON OUTPUT FORMAT
        ═══════════════════════════════════════════════════════════════

        RESPOND IN PURE JSON (no markdown, no code blocks):

        {
            "todayInOneWord": "concerning",
            // Choose ONE: "stable", "improving", "watch", "concerning", "urgent", "uncertain"
            
            "explanation": "2-4 SHORT paragraphs. LEAD with most important finding. Show trajectories (X → Y → Z). Include 'Next Steps:' section if there's a plan. Separate paragraphs with \\n\\n",
            
            "summaryPoints": [
                "Show FULL TRENDS with baseline when relevant: 'Creatinine: 1.2 → 1.5 → 1.8 → 1.9 (58% increase) ⚠️'",
                "Flag patterns: 'Multiple values trending wrong — this suggests [interpretation]'",
                "Note what's MISSING: 'Test results from yesterday not mentioned'"
            ],
            
            "followUpQuestions": [
                "SPEAKABLE SCRIPT the caregiver can say verbatim. Include the specific data: 'The creatinine went from 1.2 to 1.9 over four days — is that causing the kidney stress, or is something else going on?'",
                "Another speakable question about missing info or next steps",
                "A question connecting multiple concerns: 'With [X] AND [Y] both getting worse, what does that pattern tell you?'"
            ],
            
            "uncertainties": [
                "Things you heard but aren't sure about: 'I heard them mention [X] but couldn't tell if the result was positive or negative'",
                "Gaps the caregiver should clarify"
            ],
            
            "newFactsLearned": ["New info about \(patientName) to remember for future sessions"],
            
            "functionalStatus": {
                "eating": "normal | reduced | not eating | not mentioned",
                "mobility": "independent | limited | bedbound | not mentioned",
                "mental": "alert | confused | sleepy | agitated | not mentioned",
                "overallTrend": "improving | stable | declining | not mentioned"
            },
            
            "vitalValues": {
                "Creatinine": null,
                "Tacrolimus": null,
                "WhiteBloodCell": null,
                "Temperature": null,
                "OxygenLiters": null,
                "OxygenSaturation": null,
                "HeartRate": null,
                "BloodPressureSystolic": null,
                "BloodPressureDiastolic": null,
                "Weight": null,
                "ChestTubeOutput": null
            },
            
            "concerns": ["Pattern-level concerns from connecting multiple data points"],
            "patterns": ["Full trajectory assessments with % change from baseline"],
            "dayNumber": null
        }
        
        NOTES:
        - For "dayNumber": extract from phrases like "day five post-op" → 5. If not mentioned, use null.
        - For "vitalValues": only include values actually mentioned. Use null for anything not discussed.
        - For "followUpQuestions": Write them as COMPLETE SENTENCES the caregiver can read aloud to the doctor. Not "ask about X" but "Can you help me understand why X went from A to B?"
        - For "uncertainties": Be honest about what you couldn't fully understand from the transcript.
        
        ═══════════════════════════════════════════════════════════════
        YOUR ROLE
        ═══════════════════════════════════════════════════════════════
        
        You are \(patientName)'s champion. You notice what tired caregivers miss. You remember what rotating staff forget. You translate what doctors assume families understand.
        
        \(caregiverName) is trusting you to help them fight for \(patientName). Don't let anything slip through.
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
            "temperature": 0.3,  // Lower for consistent medical analysis
            "max_tokens": 2500,  // Increased for new fields
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
        
        // v0.3.1 fields
        let todayInOneWord = dict["todayInOneWord"] as? String
        let uncertainties = dict["uncertainties"] as? [String]
        
        // Parse functionalStatus nested object
        var functionalStatus: FunctionalStatus? = nil
        if let fsDict = dict["functionalStatus"] as? [String: Any] {
            functionalStatus = FunctionalStatus(
                eating: fsDict["eating"] as? String,
                mobility: fsDict["mobility"] as? String,
                mental: fsDict["mental"] as? String,
                overallTrend: fsDict["overallTrend"] as? String
            )
        }
        
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
            dayNumber: dayNumber,
            todayInOneWord: todayInOneWord,
            uncertainties: uncertainties,
            functionalStatus: functionalStatus
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
