//
//  ScheduleWidget.swift
//  ScheduleWidget
//
//  Created by Thilo on 05.08.22.
//

import Foundation
import WidgetKit
import SwiftUI
import Intents


private let widgetAppGroupIdentifier = "group.ch.thilojaeggi.notely"
private let widgetLessonDataKey = "notely_lesson_data"

private struct WidgetLessonPayload: Decodable {
    let currentLesson: Lesson?
    let nextLesson: Lesson?
    let dailyLessons: [Lesson]

    private enum CodingKeys: String, CodingKey {
        case currentLesson
        case nextLesson
        case dailyLessons
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentLesson = try container.decodeIfPresent(Lesson.self, forKey: .currentLesson)
        nextLesson = try container.decodeIfPresent(Lesson.self, forKey: .nextLesson)
        dailyLessons = try container.decodeIfPresent([Lesson].self, forKey: .dailyLessons) ?? []
    }
}

struct LessonEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let currentLesson: Lesson?
    let nextLesson: Lesson?
}


struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> LessonEntry {
        placeholderEntry(configuration: ConfigurationIntent(), date: Date())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (LessonEntry) -> ()) {
        let now = Date()
        let entries = timelineEntries(
            from: loadLessonPayload(),
            configuration: configuration,
            referenceDate: now
        )
        completion(entries.first ?? placeholderEntry(configuration: configuration, date: now))
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let entries = timelineEntries(
            from: loadLessonPayload(),
            configuration: configuration,
            referenceDate: now
        )

        let policy: TimelineReloadPolicy = entries.isEmpty
            ? .after(now.addingTimeInterval(15 * 60)) // no lessons → recheck later
            : .atEnd                                // follow our entries

        completion(Timeline(entries: entries, policy: policy))
    }
}


private func loadLessonPayload() -> WidgetLessonPayload? {
    let defaults = UserDefaults(suiteName: widgetAppGroupIdentifier) ?? UserDefaults.standard
    guard let jsonString = defaults.string(forKey: widgetLessonDataKey),
          let jsonData = jsonString.data(using: .utf8) else {
        return nil
    }

    do {
        return try JSONDecoder().decode(WidgetLessonPayload.self, from: jsonData)
    } catch {
        print("SchedulesWidget: failed to decode payload – \(error)")
        return nil
    }
}

private func timelineEntries(
    from payload: WidgetLessonPayload?,
    configuration: ConfigurationIntent,
    referenceDate: Date
) -> [LessonEntry] {
    guard
        let payload = payload,
        !payload.dailyLessons.isEmpty
    else {
        return [placeholderEntry(configuration: configuration, date: referenceDate)]
    }

    // Filter to lessons that have at least a start or end
    let lessons = payload.dailyLessons.filter { $0.start != nil || $0.end != nil }
    guard !lessons.isEmpty else {
        return [placeholderEntry(configuration: configuration, date: referenceDate)]
    }

    // Collect interesting times: now, all starts, all ends
    var times: Set<Date> = [referenceDate]

    for lesson in lessons {
        if let start = lesson.start {
            times.insert(start)
        }
        let end = endDate(for: lesson, fallbackFrom: referenceDate)
        times.insert(end)
    }

    let sortedTimes = times
        .filter { $0 >= referenceDate }
        .sorted()

    var entries: [LessonEntry] = []

    for time in sortedTimes {
        let (current, next) = state(at: time, lessons: lessons, referenceDate: referenceDate)

        // We *do* create entries even when both are nil so we can clear the widget
        let entry = LessonEntry(
            date: time,
            configuration: configuration,
            currentLesson: current,
            nextLesson: next
        )
        entries.append(entry)
    }

    if entries.isEmpty {
        return [placeholderEntry(configuration: configuration, date: referenceDate)]
    }

    return entries
}

private func endDate(for lesson: Lesson, fallbackFrom reference: Date) -> Date {
    if let end = lesson.end {
        return end
    }
    if let start = lesson.start {
        // fallback duration 45min if no end given
        return start.addingTimeInterval(45 * 60)
    }
    return reference
}

private func state(
    at date: Date,
    lessons: [Lesson],
    referenceDate: Date
) -> (current: Lesson?, next: Lesson?) {
    guard !lessons.isEmpty else {
        return (nil, nil)
    }

    let sorted = lessons.sorted { (a, b) in
        let sa = a.start ?? a.end ?? .distantFuture
        let sb = b.start ?? b.end ?? .distantFuture
        return sa < sb
    }

    // Find current lesson (start <= date < end)
    let current = sorted.first { lesson in
        guard let start = lesson.start else { return false }
        let end = endDate(for: lesson, fallbackFrom: referenceDate)
        return start <= date && date < end
    }

    let next: Lesson?

    if let current = current {
        let currentEnd = endDate(for: current, fallbackFrom: referenceDate)
        next = sorted.first { lesson in
            guard let start = lesson.start else { return false }
            return start > currentEnd
        }
    } else {
        // No current lesson → next is the first one that starts after now
        next = sorted.first { lesson in
            guard let start = lesson.start else { return false }
            return start > date
        }
    }

    return (current, next)
}


private func placeholderEntry(configuration: ConfigurationIntent, date: Date = Date()) -> LessonEntry {
    let lesson = placeholderLesson()
    return LessonEntry(date: date, configuration: configuration, currentLesson: lesson, nextLesson: lesson)
}

private func placeholderLesson() -> Lesson {
    Lesson(lessonName: "Mathematik", room: "A123", teacher: "Max Mustermann", time: "9:45")
}

struct ScheduleWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
            ZStack(alignment: .bottomTrailing) {
                content
                debugOverlay
            }
        }


    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {

            // ---- CURRENT LESSON ----
            if let current = entry.currentLesson {
                Text("JETZT")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                    .lineLimit(1)

                LessonCompact(
                    title: current.lessonName,
                    room: current.room,
                    teacher: current.teacher
                )
            }

            if entry.currentLesson != nil && entry.nextLesson != nil {
                Divider().padding(.vertical, 4.0)
            }

            // ---- NEXT LESSON ----
            if let next = entry.nextLesson {
                Text("UM \(next.time)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                    .lineLimit(1)

                LessonCompact(
                    title: next.lessonName,
                    room: next.room,
                    teacher: next.teacher
                )
            }
        }
        .padding(4.0)
    }
    @ViewBuilder
        private var debugOverlay: some View {
            #if DEBUG
            VStack {
                Text("↻ \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .padding(3)
                    .background(Color.black.opacity(0.35))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
                .padding(4)
            #endif
        }
}


private struct LessonCompact: View {
    let title: String
    let room: String
    let teacher: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)              // ← allow 2 lines
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)   // ← may be truncated first

                Spacer(minLength: 4)

                Text(room)
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 4)   // slightly tighter pill
                    .padding(.vertical, 1)
                    .foregroundStyle(Color.white.opacity(0.9))
                    .background(Color.blue.opacity(0.5))
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .layoutPriority(1)   // ← try to keep room visible
            }

            Text(teacher)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)       .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .configurationDisplayName("Stundenplan")
        .description("Zeigt dir immer deine aktuelle und nächste Lektion")
        .supportedFamilies([.systemSmall])
    }
}

struct ScheduleWidget_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleWidgetEntryView(entry: LessonEntry(date: Date(), configuration: ConfigurationIntent(), currentLesson: Lesson(lessonName: "Mathematik", room: "A123", teacher: "Max Mustermann", time: "9:45"), nextLesson: Lesson(lessonName: "Deutsch", room: "A205", teacher: "Elvira Schneider", time: "10:45")))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
