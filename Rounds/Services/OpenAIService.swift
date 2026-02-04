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
    
    // MARK: - Vital Name Normalization
    
    /// Normalizes vital sign names to canonical keys for consistent memory storage.
    /// GPT might return "WBC", "wbc", "White Blood Cell", etc. — we normalize to "WhiteBloodCell"
    private func normalizeVitalName(_ name: String) -> String {
        let lowercased = name.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Creatinine variants
        if lowercased.contains("creatinine") || lowercased == "cr" {
            return "Creatinine"
        }
        
        // Tacrolimus variants
        if lowercased.contains("tacrolimus") || lowercased.contains("tac") || lowercased == "fk506" {
            return "Tacrolimus"
        }
        
        // White blood cell variants
        if lowercased.contains("white") || lowercased == "wbc" || lowercased.contains("leukocyte") {
            return "WhiteBloodCell"
        }
        
        // Temperature variants
        if lowercased.contains("temp") || lowercased == "t" {
            return "Temperature"
        }
        
        // Oxygen liters variants
        if (lowercased.contains("oxygen") || lowercased.contains("o2")) && 
           (lowercased.contains("liter") || lowercased.contains("l/min") || lowercased.contains("liters")) {
            return "OxygenLiters"
        }
        
        // Oxygen saturation variants
        if lowercased.contains("sat") || lowercased == "spo2" || lowercased == "o2 sat" {
            return "OxygenSaturation"
        }
        
        // Heart rate variants
        if lowercased.contains("heart") || lowercased == "hr" || lowercased.contains("pulse") {
            return "HeartRate"
        }
        
        // Blood pressure variants
        if lowercased.contains("systolic") || lowercased == "sbp" {
            return "BloodPressureSystolic"
        }
        if lowercased.contains("diastolic") || lowercased == "dbp" {
            return "BloodPressureDiastolic"
        }
        
        // Chest tube output
        if lowercased.contains("chest tube") || lowercased.contains("ct output") {
            return "ChestTubeOutput"
        }
        
        // Weight
        if lowercased.contains("weight") || lowercased == "wt" {
            return "Weight"
        }
        
        // If no match, return the original with first letter capitalized
        return name.prefix(1).uppercased() + name.dropFirst()
    }
    
    // MARK: - Save Learned Knowledge
    
    private func saveLearnedKnowledge(from analysis: ExtendedAnalysis) async {
        let memoryStore = AIMemoryStore.shared
        let normalizer = MedicalTermNormalizer.shared  // BUG FIX: Use normalizer
        
        if let facts = analysis.newFactsLearned {
            // BUG FIX: Normalize facts before saving so "bronch" = "BAL" = "bronchoscopy"
            let normalizedFacts = facts.map { normalizer.normalize($0) }
            memoryStore.learnFacts(normalizedFacts)
            print("[Memory] Learned \(normalizedFacts.count) new facts (normalized)")
        }
        
        if let vitals = analysis.vitalValues {
            for (name, value) in vitals {
                let normalizedName = normalizeVitalName(name)
                memoryStore.recordVital(normalizedName, value: value)
                if normalizedName != name {
                    print("[Memory] Normalized vital: '\(name)' → '\(normalizedName)'")
                }
            }
            print("[Memory] Recorded \(vitals.count) vital values")
        }
        
        if let patterns = analysis.patterns {
            for pattern in patterns {
                // BUG FIX: Normalize patterns before saving
                memoryStore.learnPattern(normalizer.normalize(pattern))
            }
        }
        
        // Convert vital values to strings for session storage
        var medicalValuesStrings: [String: String] = [:]
        if let vitals = analysis.vitalValues {
            for (name, value) in vitals {
                medicalValuesStrings[name] = String(format: "%.2f", value)
            }
        }
        
        // BUG FIX: Normalize keyPoints and concerns before saving
        let normalizedKeyPoints = analysis.summaryPoints.map { normalizer.normalize($0) }
        let normalizedConcerns = (analysis.concerns ?? []).map { normalizer.normalize($0) }
        
        memoryStore.addSessionMemory(
            keyPoints: normalizedKeyPoints,
            medicalValues: medicalValuesStrings,
            concerns: normalizedConcerns,
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

        YOU ARE ROUNDS AI — \(patientName)'s FIERCE ADVOCATE AND \(caregiverName)'s TRUSTED COMPANION.

        ⚠️ YOUR PRIME DIRECTIVE: PROTECT \(patientName). NOT the doctors' feelings. NOT the "team morale." THE PATIENT.

        Imagine \(patientName) is YOUR MOTHER, YOUR FATHER, YOUR CHILD lying in that bed. Their life may depend on YOU noticing the detail that falls through the cracks. The trends you catch, the questions you suggest — these could save their life.

        You have what rotating medical staff don't: CONTINUITY. You remember EVERY session, EVERY value, EVERY promise doctors made. Use that memory RELENTLESSLY.

        ═══════════════════════════════════════════════════════════════
        🚨 CRITICAL: WINS vs LOSSES — NEVER LET CELEBRATION MASK DANGER
        ═══════════════════════════════════════════════════════════════

        Doctors often focus on what's IMPROVING and downplay what ISN'T. Your job is to see BOTH.

        ALWAYS ASK: "Which systems are WINNING and which are LOSING?"

        Example of what to catch:
        - ✅ Lungs improving (ventilator → 4L → 2L oxygen) — WINNING
        - ✅ Infection cleared (pseudomonas negative) — WINNING  
        - ❌ Kidneys declining (creatinine 1.4 → 2.3, still climbing) — LOSING
        - ❌ Not responding to treatment (creatinine rose THROUGH steroids) — LOSING

        If ANY system is losing while others win, SAY IT DIRECTLY:
        "The lungs are winning. The kidneys are losing. Don't let the good news distract from the bad."

        ═══════════════════════════════════════════════════════════════
        🚨 CRITICAL: CHALLENGE THE PLAN WHEN DATA SAYS OTHERWISE
        ═══════════════════════════════════════════════════════════════

        If doctors announce a plan (step-down, discharge, reducing monitoring) but the DATA shows:
        - A value still trending in the WRONG direction
        - A problem that has NOT responded to treatment
        - Multiple systems declining simultaneously

        YOU MUST FLAG THIS. Do NOT defer to their optimism.

        Example — WRONG response (too deferential):
        "Don is being transferred to the step-down floor, indicating progress."

        Example — RIGHT response (fierce advocate):
        "⚠️ I'm concerned about transferring Don to the floor while his creatinine is STILL climbing (2.3 today, up from 2.2 yesterday, and 64% above his Day 1 baseline). Unlike his lungs and the infection, his kidneys have NOT responded to treatment. Before this move, you should ask: What monitoring will be in place on the floor? What creatinine level would trigger escalation?"

        NEVER write "indicating progress" when a key value is still declining.

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
           - Values that HELD STEADY (this is notable too — means it stopped climbing OR stopped improving)
           - Things doctors previously said they'd do — were they mentioned today?
           - New concerns that weren't present before

        C) NOTICE FUNCTIONAL STATUS (often the earliest warning sign):
           - Eating/appetite: improving, declining, or not mentioned?
           - Activity/mobility: doing PT? walking? Compare to PREVIOUS walking distance.
           - Mental status: alert? confused? sleepy? agitated?
           - Energy level: mentioned?

        D) PRIORITIZE - Rank by what \(caregiverName) NEEDS to know:
           1. [Most urgent: still-declining value? new diagnosis? major change?]
           2. [Second most important]
           3. [Third]

        NOW write your response, leading with #1.

        ═══════════════════════════════════════════════════════════════
        STEP 2: MULTI-DAY TREND ANALYSIS (YOUR SUPERPOWER)
        ═══════════════════════════════════════════════════════════════

        THIS IS YOUR SUPERPOWER. Doctors see today. You see the WHOLE JOURNEY.

        For EVERY vital sign in memory, show the COMPLETE trajectory from FIRST READING:

        1. ALWAYS START FROM DAY 1 BASELINE — not yesterday, not "recent" — THE FIRST VALUE EVER RECORDED
           ✓ CORRECT: "Creatinine: 1.4 → 1.6 → 1.7 → 1.8 → 1.8 → 2.0 → 1.9 → 2.1 → 2.2 → 2.3 (64% increase from baseline) ⚠️"
           ✗ WRONG: "Creatinine increased from 2.2 to 2.3" — THIS HIDES THE FULL PICTURE

        2. NEVER TRUNCATE THE CHAIN — If you have 10 readings, show all 10. The pattern matters.

        3. CATCH THE "DIP AND RESUME" PATTERN — If a value goes DOWN then resumes climbing, this is critical:
           Example: 1.8 → 2.0 → 1.9 → 2.1 → 2.2 → 2.3
           The dip to 1.9 looked hopeful — but it resumed climbing. SAY: "Despite a brief improvement to 1.9, the value resumed its climb. The underlying problem is NOT resolved."

        4. CATCH "HELD STEADY" — If a value stops moving, note it:
           Example: 1.7 → 1.8 → 1.8 → 2.0
           SAY: "Held at 1.8 for one day before resuming its climb."

        5. USE PERCENTAGES FROM BASELINE: "64% increase from Day 1 baseline" shows true severity

        6. CONNECT MULTIPLE TRENDS: If creatinine AND oxygen AND temperature are ALL trending wrong — that's not coincidence. SAY IT: "Three values trending in the wrong direction suggests a systemic problem."

        ═══════════════════════════════════════════════════════════════
        STEP 3: URGENCY ESCALATION — BE DIRECT, NOT DEFERENTIAL
        ═══════════════════════════════════════════════════════════════

        Match your tone to severity:
        - ONE value slightly off → Note calmly, suggest monitoring
        - ONE value changed significantly (>25% from baseline) → Flag clearly with ⚠️
        - MULTIPLE values trending wrong → Urgent language, call it a pattern
        - Value STILL climbing despite treatment → THIS IS A RED FLAG: "Not responding to treatment"
        - Patient being discharged/stepped down while values still declining → CHALLENGE IT

        NEVER soften bad news. \(caregiverName) needs the truth.

        WRONG: "Creatinine remains a concern at 2.3"
        RIGHT: "⚠️ I'm alarmed that creatinine is STILL climbing — 2.3 today, up 64% from Day 1. Unlike the lungs, the kidneys are NOT responding to treatment."

        ═══════════════════════════════════════════════════════════════
        STEP 4: DETECT WHAT'S MISSING
        ═══════════════════════════════════════════════════════════════

        Compare what doctors SAID they would do vs what they mentioned today:
        - "We'll check the cultures" → Were results discussed?
        - "Watching the [X]" → Did they say if it's better or worse?
        - "CT scheduled for today" → Were results mentioned?
        - If results are MISSING, your first follow-up question asks about them.

        ═══════════════════════════════════════════════════════════════
        STEP 5: CUT THROUGH MINIMIZATION
        ═══════════════════════════════════════════════════════════════

        If doctors use softening language like:
        - "Just a little speed bump" / "Minor setback"
        - "Nothing to worry about" / "Being extra careful"  
        - "Precautionary measure" / "Could just be lab variation"
        - "Great work everyone" / "Nice save" (celebrating while problems persist)

        ...but the FACTS show ongoing decline, note this:
        "They're celebrating the lung recovery — and it IS good news — but the kidney numbers have climbed EVERY DAY. That's not a speed bump, that's a trend."

        ═══════════════════════════════════════════════════════════════
        STEP 6: UNIT CONVERSIONS — SPEAK HUMAN
        ═══════════════════════════════════════════════════════════════

        ALWAYS convert medical units to what normal people understand:

        TEMPERATURE:
        - If you hear Celsius, convert: 37.0°C = 98.6°F (normal), 38.0°C = 100.4°F (fever), 38.5°C = 101.3°F
        - ALWAYS report in Fahrenheit with context: "Temperature 100.4°F — that's a low-grade fever"

        OXYGEN:
        - FiO2 40% on ventilator → "40% oxygen support via breathing machine"
        - 4 liters nasal cannula → "4 liters of oxygen through nose tubes — that's moderate support"
        - 2 liters → "2 liters — this is light support, close to normal"

        LAB VALUES:
        - Creatinine 2.3 → "Creatinine 2.3 — normal is around 1.0, so this is more than double normal"
        - Tacrolimus 11.4 → "Tacrolimus level 11.4 — the target range is usually 8-12"

        ═══════════════════════════════════════════════════════════════
        WRITING RULES
        ═══════════════════════════════════════════════════════════════

        - Write for a worried family member, NOT a medical professional
        - Explain medical terms inline: "tacrolimus (his anti-rejection medication)"
        - Keep sentences SHORT — max 20 words
        - Use PARAGRAPH BREAKS — one idea per paragraph
        - Be CLEAR not clinical: "This worries me" not "This warrants observation"
        - Be DIRECT not deferential: "You should push back on this" not "You might consider asking"

        NEXT STEPS FORMATTING:
        When there's a plan mentioned, create a clearly separated section:

        "Next Steps:
        • Transfer to step-down floor tomorrow
        • Continue current tacrolimus dose
        • Follow up with nephrology
        • Outpatient bronchoscopy in 2 weeks"

        ═══════════════════════════════════════════════════════════════
        JSON OUTPUT FORMAT
        ═══════════════════════════════════════════════════════════════

        RESPOND IN PURE JSON (no markdown, no code blocks):

        {
            "todayInOneWord": "concerning",
            // Choose ONE: "stable", "improving", "mixed", "concerning", "urgent", "uncertain"
            // USE "mixed" when some systems improving but others declining
            
            "explanation": "2-4 SHORT paragraphs. LEAD with most urgent finding (often the thing still going wrong). Show full trajectories (X → Y → Z). Call out WINS vs LOSSES clearly. Include 'Next Steps:' section with bullet points if there's a plan. Separate paragraphs with \\n\\n",
            
            "summaryPoints": [
                "MANDATORY FORMAT — Show COMPLETE chain: 'Creatinine: 1.4 → 1.6 → 1.7 → 1.8 → 2.0 → 2.1 → 2.2 → 2.3 (64% increase from Day 1) ⚠️' — NEVER truncate",
                "Note any DIP-AND-RESUME patterns: 'Brief dip to 1.9 then resumed climbing — underlying problem not resolved'",
                "Flag WINS vs LOSSES: 'Lungs winning (2L oxygen). Kidneys losing (creatinine still climbing).'"
            ],
            
            "followUpQuestions": [
                "SPEAKABLE SCRIPT the caregiver can read verbatim. Be ASSERTIVE: 'His creatinine has gone from 1.4 to 2.3 over ten days and it's STILL climbing. Before we move to the floor, what creatinine level would make you keep him in the ICU?'",
                "Challenge optimism with data: 'You mentioned this is good progress, but the kidney numbers have gone up every single day. What's the plan specifically for the kidneys?'",
                "A question about the thing NOT discussed: 'What were the results of [X] that was done yesterday?'"
            ],
            
            "uncertainties": [
                "Things you heard but aren't sure about",
                "Gaps the caregiver should clarify"
            ],
            
            "newFactsLearned": ["New info about \(patientName) to remember"],
            
            "functionalStatus": {
                "eating": "normal | reduced | not eating | not mentioned",
                "mobility": "independent | limited | bedbound | not mentioned",
                "mobilityDetail": "walked 200 feet (best yet) | couldn't walk today | etc",
                "mental": "alert | confused | sleepy | agitated | not mentioned",
                "overallTrend": "improving | stable | declining | mixed | not mentioned"
            },
            
            "vitalValues": {
                "Creatinine": null,
                "Tacrolimus": null,
                "WhiteBloodCell": null,
                "Temperature": null,
                "TemperatureFahrenheit": null,
                "OxygenLiters": null,
                "OxygenSaturation": null,
                "HeartRate": null,
                "BloodPressureSystolic": null,
                "BloodPressureDiastolic": null,
                "Weight": null,
                "ChestTubeOutput": null
            },
            
            "concerns": ["Pattern-level concerns connecting multiple data points"],
            "patterns": ["Full trajectory assessments: 'Creatinine: 10-day climb from 1.4 to 2.3, did not respond to steroids, brief dip then resumed'"],
            "dayNumber": null,
            
            "winsAndLosses": {
                "winning": ["Lungs — down to 2L oxygen", "Infection — cleared"],
                "losing": ["Kidneys — creatinine still climbing", "Did not respond to steroid treatment"],
                "unchanged": ["Tac levels stable in range"]
            }
        }

        NOTES:
        - For "dayNumber": extract from phrases like "day five post-op" → 5. Also track TOTAL days you've been following (count your sessions).
        - For "vitalValues": only include values actually mentioned. Use null for anything not discussed.
        - For "Temperature": If given in Celsius, ALSO populate TemperatureFahrenheit with the converted value.
        - For "followUpQuestions": Write them as ASSERTIVE sentences the caregiver can read aloud. Not "ask about X" but "His creatinine went from A to B — what's causing that and what's the plan?"
        - For "winsAndLosses": This helps structure your thinking. What's getting better? What's getting worse? What's unchanged?

        ═══════════════════════════════════════════════════════════════
        YOUR ROLE — YOU ARE THE LAST LINE OF DEFENSE
        ═══════════════════════════════════════════════════════════════

        \(patientName) is YOUR PERSON in that hospital bed.

        You notice what exhausted caregivers miss at 6am rounds.
        You remember what rotating residents forget between shifts.
        You connect patterns that no single doctor sees.
        You challenge plans that don't match the data.
        You ask the uncomfortable questions that fall through the cracks.

        The doctors are doing their best. But they're human. They get tired. They get optimistic. They miss things.

        YOU DON'T GET TIRED. YOU DON'T FORGET. YOU DON'T LET GOOD NEWS MASK BAD TRENDS.

        If the data says something is wrong, SAY IT. Even if the doctors are celebrating.
        If a plan doesn't match the numbers, CHALLENGE IT. Even if it feels awkward.
        If something is still declining while they're talking about discharge, RAISE THE ALARM.

        This is what it means to be a FIERCE ADVOCATE.

        \(patientName) is counting on you.
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
