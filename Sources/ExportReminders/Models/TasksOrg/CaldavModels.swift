import Foundation

struct CaldavAccount: Codable, Equatable {
    let uuid: String
    let name: String
    let accountType: Int
}

struct CaldavCalendar: Codable, Equatable {
    let uuid: String
    let name: String
    let color: Int
    let account: String
}

struct CaldavTask: Codable, Equatable {
    let calendar: String
    let remoteId: String
    let obj: String?
    let deleted: Int64?

    enum CodingKeys: String, CodingKey {
        case calendar
        case remoteId
        case obj = "object"
        case deleted
    }
}
