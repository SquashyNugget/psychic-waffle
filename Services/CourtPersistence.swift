import Foundation

struct CourtPersistence {
    private static let key = "badminton-court-manager.courts.v2"

    func load() -> [CourtTimer] {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([CourtTimer].self, from: data),
              decoded.count == 4,
              decoded.map(\.id) == [1, 2, 3, 4] else {
            return TimerEngine.initialCourts()
        }
        return decoded
    }

    func save(_ courts: [CourtTimer]) {
        guard let data = try? JSONEncoder().encode(courts) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
