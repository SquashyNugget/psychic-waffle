import ActivityKit
import Foundation

/// Codable payload shared by the app and the Live Activity extension.
/// Never put an ObservableObject or an app-only type in an ActivityKit payload.
struct CourtActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var activeCourts: [LiveCourt]
    }

    var sessionName: String = "Badminton Courts"
}

struct LiveCourt: Codable, Hashable, Identifiable {
    enum Kind: String, Codable {
        case knockUp
        case stopwatch
    }

    let id: Int
    let kind: Kind
    /// Date to count forward from for a stopwatch, or the start of a 120s ring.
    let startDate: Date
    /// Present only for Knock Up; native timer Text uses this to count down.
    let endDate: Date?
}
