//
//  Lesson.swift
//  ScheduleWidgetExtension
//
//  Created by Thilo on 07.08.22.
//

import Foundation

public struct Lesson: Decodable {
    let lessonName: String
    let room: String
    let teacher: String
    let time: String
    let start: Date?
    let end: Date?

    public init(
        lessonName: String,
        room: String,
        teacher: String,
        time: String,
        start: Date? = nil,
        end: Date? = nil
    ) {
        self.lessonName = lessonName
        self.room = room
        self.teacher = teacher
        self.time = time
        self.start = start
        self.end = end
    }

    private enum CodingKeys: String, CodingKey {
        case lessonName
        case room
        case teacher
        case time
        case start
        case end
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lessonName = try container.decodeIfPresent(String.self, forKey: .lessonName) ?? ""
        room = try container.decodeIfPresent(String.self, forKey: .room) ?? ""
        teacher = try container.decodeIfPresent(String.self, forKey: .teacher) ?? ""
        time = try container.decodeIfPresent(String.self, forKey: .time) ?? ""
        start = Lesson.decodeDate(from: container, forKey: .start)
        end = Lesson.decodeDate(from: container, forKey: .end)
    }

    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Date? {
        guard let value = try? container.decodeIfPresent(String.self, forKey: key)
              else {
            return nil
        }
        let text = value

        let formats: [ISO8601DateFormatter] = [
            {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter
            }(),
            {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                return formatter
            }()
        ]

        for formatter in formats {
            if let parsed = formatter.date(from: text) {
                return parsed
            }
        }

        return nil
    }
}
