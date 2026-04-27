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
private let widgetPremiumKey = "is_premium"

// MARK: - Data Models

/// Supports both the new multi-day format (`days` dictionary keyed by "yyyy-MM-dd")
/// and the legacy single-day format (`dailyLessons` array).
private struct WidgetLessonPayload: Decodable {
    let lastSynced: String?
    let days: [String: [Lesson]]

    // Legacy fields for backward compatibility after app update
    let dailyLessons: [Lesson]

    private enum CodingKeys: String, CodingKey {
        case lastSynced, days, dailyLessons
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastSynced = try container.decodeIfPresent(String.self, forKey: .lastSynced)
        days = try container.decodeIfPresent([String: [Lesson]].self, forKey: .days) ?? [:]
        dailyLessons = try container.decodeIfPresent([Lesson].self, forKey: .dailyLessons) ?? []
    }

    /// Returns lessons for a date key ("yyyy-MM-dd"), falling back to legacy
    /// `dailyLessons` when the multi-day format hasn't been written yet.
    func lessons(for dateKey: String) -> [Lesson] {
        if !days.isEmpty {
            return days[dateKey] ?? []
        }
        return dailyLessons
    }

    var isMultiDay: Bool { !days.isEmpty }
}

struct LessonEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let currentLesson: Lesson?
    let nextLesson: Lesson?
    let isStale: Bool
    let hasData: Bool
}

// MARK: - Timeline Provider

struct Provider: IntentTimelineProvider {
    private static let calendar = Calendar.current
    /// Data older than 48 hours is considered stale.
    private static let stalenessThreshold: TimeInterval = 48 * 3600

    func placeholder(in context: Context) -> LessonEntry {
        LessonEntry(
            date: Date(),
            configuration: ConfigurationIntent(),
            currentLesson: placeholderLesson(),
            nextLesson: placeholderLesson(),
            isStale: false,
            hasData: true
        )
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (LessonEntry) -> ()) {
        let now = Date()
        let payload = loadLessonPayload()
        let todayKey = Self.dateKey(for: now)
        let lessons = payload?.lessons(for: todayKey) ?? []
        let (current, next) = Self.lessonState(at: now, lessons: lessons)

        completion(LessonEntry(
            date: now,
            configuration: configuration,
            currentLesson: current,
            nextLesson: next,
            isStale: Self.isDataStale(payload),
            hasData: payload != nil
        ))
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let calendar = Self.calendar

        let payload = loadLessonPayload()
        let isStale = Self.isDataStale(payload)
        let hasData = payload != nil

        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        let todayKey = Self.dateKey(for: todayStart)
        let tomorrowKey = Self.dateKey(for: tomorrowStart)

        let todayLessons = payload?.lessons(for: todayKey) ?? []
        let tomorrowLessons = payload?.lessons(for: tomorrowKey) ?? []

        var entries: [LessonEntry] = []

        // Today's entries (from now through end of school)
        entries.append(contentsOf: Self.entriesForDay(
            lessons: todayLessons,
            from: now,
            configuration: configuration,
            isStale: isStale,
            hasData: hasData
        ))

        // Tomorrow's entries (from midnight onward)
        entries.append(contentsOf: Self.entriesForDay(
            lessons: tomorrowLessons,
            from: tomorrowStart,
            configuration: configuration,
            isStale: isStale,
            hasData: hasData
        ))

        // Always have at least one entry
        if entries.isEmpty {
            entries.append(LessonEntry(
                date: now,
                configuration: configuration,
                currentLesson: nil,
                nextLesson: nil,
                isStale: isStale,
                hasData: hasData
            ))
        }

        // Refresh tomorrow morning at 5 AM, or in 4 hours – whichever is sooner.
        // This ensures the widget re-reads UserDefaults daily even without the app.
        let tomorrowMorning = tomorrowStart.addingTimeInterval(5 * 3600)
        let fourHoursFromNow = now.addingTimeInterval(4 * 3600)
        let refreshDate = min(tomorrowMorning, fourHoursFromNow)

        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    // MARK: - Entry Generation

    /// Builds timeline entries for a single day's lessons, starting from `from`.
    /// Creates entries at each lesson start/end so the widget transitions smoothly.
    private static func entriesForDay(
        lessons: [Lesson],
        from startTime: Date,
        configuration: ConfigurationIntent,
        isStale: Bool,
        hasData: Bool
    ) -> [LessonEntry] {
        // Even with no lessons, emit one entry so the widget shows "Keine Lektionen"
        guard !lessons.isEmpty else {
            return [LessonEntry(
                date: startTime,
                configuration: configuration,
                currentLesson: nil,
                nextLesson: nil,
                isStale: isStale,
                hasData: hasData
            )]
        }

        let filtered = lessons.filter { $0.start != nil || $0.end != nil }
        guard !filtered.isEmpty else {
            return [LessonEntry(
                date: startTime,
                configuration: configuration,
                currentLesson: nil,
                nextLesson: nil,
                isStale: isStale,
                hasData: hasData
            )]
        }

        // Collect all transition points
        var times: Set<Date> = [startTime]
        for lesson in filtered {
            if let s = lesson.start { times.insert(s) }
            if let e = endDate(for: lesson) { times.insert(e) }
        }

        let sortedTimes = times.filter { $0 >= startTime }.sorted()
        var entries: [LessonEntry] = []

        for time in sortedTimes {
            let (current, next) = lessonState(at: time, lessons: filtered)
            entries.append(LessonEntry(
                date: time,
                configuration: configuration,
                currentLesson: current,
                nextLesson: next,
                isStale: isStale,
                hasData: hasData
            ))
        }

        return entries
    }

    // MARK: - Lesson State

    private static func lessonState(at date: Date, lessons: [Lesson]) -> (Lesson?, Lesson?) {
        let sorted = lessons.sorted {
            ($0.start ?? .distantFuture) < ($1.start ?? .distantFuture)
        }

        let current = sorted.first { lesson in
            guard let start = lesson.start else { return false }
            let end = endDate(for: lesson) ?? start.addingTimeInterval(45 * 60)
            return start <= date && date < end
        }

        let next: Lesson?
        if let current = current {
            let currentEnd = endDate(for: current) ?? current.start!.addingTimeInterval(45 * 60)
            next = sorted.first { lesson in
                guard let start = lesson.start else { return false }
                return start >= currentEnd
            }
        } else {
            next = sorted.first { lesson in
                guard let start = lesson.start else { return false }
                return start > date
            }
        }

        return (current, next)
    }

    // MARK: - Helpers

    private static func endDate(for lesson: Lesson) -> Date? {
        if let end = lesson.end { return end }
        if let start = lesson.start { return start.addingTimeInterval(45 * 60) }
        return nil
    }

    private static func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    private static func isDataStale(_ payload: WidgetLessonPayload?) -> Bool {
        guard let syncedString = payload?.lastSynced else { return true }

        let formats: [ISO8601DateFormatter] = [{
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }(), {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()]

        for fmt in formats {
            if let syncedDate = fmt.date(from: syncedString) {
                return Date().timeIntervalSince(syncedDate) > stalenessThreshold
            }
        }
        return true
    }

    /// Reads the premium flag fresh from the shared app-group container.
    static func readIsPremium() -> Bool {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupIdentifier) else {
            return false
        }
        defaults.synchronize()
        // Premium flag is stored as a string "true"/"false" to avoid
        // Dart bool → NSNumber bridging issues through home_widget.
        if let str = defaults.string(forKey: widgetPremiumKey) {
            return str == "true"
        }
        // Fallback: also accept a legacy bool value
        return defaults.bool(forKey: widgetPremiumKey)
    }
}

// MARK: - Data Loading

private func loadLessonPayload() -> WidgetLessonPayload? {
    let defaults = UserDefaults(suiteName: widgetAppGroupIdentifier) ?? UserDefaults.standard
    defaults.synchronize()
    guard let jsonString = defaults.string(forKey: widgetLessonDataKey),
          let jsonData = jsonString.data(using: .utf8) else {
        return nil
    }

    do {
        return try JSONDecoder().decode(WidgetLessonPayload.self, from: jsonData)
    } catch {
        print("ScheduleWidget: failed to decode payload – \(error)")
        return nil
    }
}

private func placeholderLesson() -> Lesson {
    Lesson(lessonName: "Mathematik", room: "A123", teacher: "Max Mustermann", time: "9:45")
}

// MARK: - Views

struct ScheduleWidgetEntryView: View {
    var entry: Provider.Entry

    /// Read premium status fresh from UserDefaults at render time.
    private var isPremium: Bool {
        Provider.readIsPremium()
    }

    var body: some View {
            ZStack(alignment: .bottomTrailing) {
                if isPremium {
                    if !entry.hasData {
                        noDataView
                    } else {
                        content
                    }
                } else {
                    premiumOverlay
                }
                debugOverlay
            }
        }

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            Text("Öffne Notely")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
    }

    private var premiumOverlay: some View {
        VStack(spacing: 8) {
            if let uiImage = UIImage(named: "PremiumIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            } else {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.yellow)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            }

            VStack(spacing: 2) {
                Text("Notely Premium")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                    Text("Freischalten")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.currentLesson == nil && entry.nextLesson == nil {
                // No lessons for this time period
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("Keine Lektionen")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    if entry.isStale {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 8))
                            Text("Öffne Notely")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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

                // Stale data hint at the bottom
                if entry.isStale {
                    Spacer(minLength: 2)
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8))
                        Text("Öffne Notely")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.orange)
                }
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
            let isPremium = Provider.readIsPremium()
            let widgetURL = isPremium ? URL(string: "notely://") : URL(string: "notely://paywall")

            if #available(iOSApplicationExtension 17.0, *) {
                ScheduleWidgetEntryView(entry: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(widgetURL)
            } else {
                ScheduleWidgetEntryView(entry: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .widgetURL(widgetURL)
            }

        }
        .configurationDisplayName("Stundenplan")
        .description("Zeigt dir immer deine aktuelle und nächste Lektion")
        .supportedFamilies([.systemSmall])
    }
}

struct ScheduleWidget_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleWidgetEntryView(entry: LessonEntry(date: Date(), configuration: ConfigurationIntent(), currentLesson: Lesson(lessonName: "Mathematik", room: "A123", teacher: "Max Mustermann", time: "9:45"), nextLesson: Lesson(lessonName: "Deutsch", room: "A205", teacher: "Elvira Schneider", time: "10:45"), isStale: false, hasData: true))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
