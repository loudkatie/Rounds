//
//  SessionStore.swift
//  Rounds
//
//  Local persistence for recording sessions using FileManager.
//

import Foundation

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published private(set) var sessions: [RecordingSession] = []

    private let fileManager = FileManager.default
    private let fileName = "rounds_sessions.json"

    private var fileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }

    private init() {
        loadSessions()
    }

    // MARK: - CRUD Operations

    func saveSession(_ session: RecordingSession) {
        // Check if session already exists (update) or is new (insert)
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0) // Most recent first
        }
        persistToDisk()
        print("[SessionStore] Saved session: \(session.id)")
    }

    func deleteSession(_ session: RecordingSession) {
        sessions.removeAll { $0.id == session.id }
        persistToDisk()
        print("[SessionStore] Deleted session: \(session.id)")
    }

    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persistToDisk()
    }

    func getSession(by id: UUID) -> RecordingSession? {
        sessions.first { $0.id == id }
    }

    // MARK: - Persistence

    private func loadSessions() {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("[SessionStore] No saved sessions found")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try JSONDecoder().decode([RecordingSession].self, from: data)
            print("[SessionStore] Loaded \(sessions.count) sessions")
        } catch {
            print("[SessionStore] Failed to load sessions: \(error)")
        }
    }

    private func persistToDisk() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL)
            print("[SessionStore] Persisted \(sessions.count) sessions to disk")
        } catch {
            print("[SessionStore] Failed to persist sessions: \(error)")
        }
    }

    // MARK: - Helpers

    func clearAllSessions() {
        sessions.removeAll()
        persistToDisk()
    }
}
