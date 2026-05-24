import SwiftUI

enum CarePart: String, CaseIterable, Identifiable, Codable {
    case hair = "髪"
    case eyeArea = "目元"
    case eyes = "目"
    case teeth = "歯"
    case hands = "手"
    case faceBody = "顔・からだ"
    case body = "からだ"
    case other = "その他"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .hair: "comb"
        case .eyeArea: "eye"
        case .eyes: "eyeglasses"
        case .teeth: "mouth"
        case .hands: "hand.raised"
        case .faceBody: "person"
        case .body: "figure.mind.and.body"
        case .other: "circle.grid.2x2"
        }
    }
}

enum IntervalUnit: String, CaseIterable, Identifiable, Codable {
    case day = "日"
    case week = "週間"
    case month = "ヶ月"
    case year = "年"

    var id: String { rawValue }
}

enum NotificationTiming: String, CaseIterable, Identifiable, Codable {
    case none = "通知しない"
    case dueDay = "当日"
    case threeDaysBefore = "3日前"
    case sevenDaysBefore = "7日前"
    case fourteenDaysBefore = "14日前"
    case thirtyDaysBefore = "30日前"
    case soonStart = "そろそろ開始時"

    var id: String { rawValue }
}

enum MaintenanceStatus: String, CaseIterable {
    case unrecorded = "まずは前回日を記録"
    case plenty = "まだ余裕"
    case soon = "そろそろ予約確認"
    case nearDue = "目安日に近いです"
    case overdue = "期限超過"
    case deferred = "あとで確認中"
}

enum AppTheme: String, CaseIterable, Identifiable {
    case cleanBlue = "Clean Blue"
    case softGreen = "Soft Green"
    case gentlePink = "Gentle Pink"
    case warmGray = "Warm Gray"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .cleanBlue: Color(red: 0.18, green: 0.47, blue: 0.90)
        case .softGreen: Color(red: 0.18, green: 0.58, blue: 0.39)
        case .gentlePink: Color(red: 0.86, green: 0.42, blue: 0.55)
        case .warmGray: Color(red: 0.42, green: 0.40, blue: 0.36)
        }
    }

    var softBackground: Color {
        switch self {
        case .cleanBlue: Color(red: 0.94, green: 0.97, blue: 1.0)
        case .softGreen: Color(red: 0.94, green: 0.98, blue: 0.95)
        case .gentlePink: Color(red: 1.0, green: 0.95, blue: 0.96)
        case .warmGray: Color(red: 0.96, green: 0.95, blue: 0.93)
        }
    }
}
