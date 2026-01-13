import Foundation

// MARK: - History Entry Model

struct ProblemHistoryEntry: Identifiable, Codable {
    let id: UUID
    let problem: String
    let solution: ProblemSolution
    let matchedPatents: [Patent]
    let date: Date

    init(problem: String, solution: ProblemSolution, matchedPatents: [Patent]) {
        self.id = UUID()
        self.problem = problem
        self.solution = solution
        self.matchedPatents = matchedPatents
        self.date = Date()
    }
}

// MARK: - History Store

class ProblemHistoryStore: ObservableObject {
    static let shared = ProblemHistoryStore()

    @Published var history: [ProblemHistoryEntry] = []

    private let storageKey = "problemSolverHistory"
    private let maxHistoryItems = 20

    private init() {
        loadHistory()
    }

    func addEntry(problem: String, solution: ProblemSolution, matchedPatents: [Patent]) {
        let entry = ProblemHistoryEntry(
            problem: problem,
            solution: solution,
            matchedPatents: matchedPatents
        )

        // Add to beginning of list
        history.insert(entry, at: 0)

        // Keep only recent items
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }

        saveHistory()
    }

    func deleteEntry(_ entry: ProblemHistoryEntry) {
        history.removeAll { $0.id == entry.id }
        saveHistory()
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            history = try JSONDecoder().decode([ProblemHistoryEntry].self, from: data)
        } catch {
            history = []
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // Silent fail
        }
    }
}
