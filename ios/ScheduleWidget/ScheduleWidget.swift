//
//  ScheduleWidget.swift
//  ScheduleWidget
//
//  Created by Thilo on 05.08.22.
//

import WidgetKit
import SwiftUI
import Intents


struct LessonEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let currentLesson: Lesson
    let nextLesson: Lesson
}

struct Provider: IntentTimelineProvider {
    
    
    
    func placeholder(in context: Context) -> LessonEntry {
        print("Get Placceholder called")

        return LessonEntry(date: Date(), configuration: ConfigurationIntent(), currentLesson: Lesson(lessonName: "Mathematik", room: "A123", teacher: "Max Mustermann", time: "9:45"), nextLesson: Lesson(lessonName: "Deutsch", room: "A205", teacher: "Elvira Schneider", time: "9:45"))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (LessonEntry) -> ()) {
        print("Get Snapshot called")
        let entry = LessonEntry(date: Date(), configuration: ConfigurationIntent(), currentLesson: Lesson(lessonName: "Mathematik", room: "A123", teacher: "Max Mustermann", time: "9:45"), nextLesson: Lesson(lessonName: "Deutsch", room: "A205", teacher: "Elvira Schneider", time: "9:45"))
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("Get Timeline called")

        
        let currentDate = Date()
            let startOfDay = Calendar.current.startOfDay(for: currentDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let entries: [LessonEntry] = [
            LessonEntry(date: Calendar.current.date(byAdding: .second, value: 30, to: currentDate)!, configuration: configuration, currentLesson: Lesson(lessonName: "Mathematik", room: "A123", teacher: "Stephan Hartmann", time: "9:45"), nextLesson: Lesson(lessonName: "Deutsch", room: "A205", teacher: "Maja Carapovic", time: "9:45")),
            LessonEntry(date: Calendar.current.date(byAdding: .second, value: 60, to: currentDate)!, configuration: configuration, currentLesson: Lesson(lessonName: "Deutsch", room: "A205", teacher: "Maja Carapovic", time: "9:45"), nextLesson: Lesson(lessonName: "Mathematik", room: "A123", teacher: "Stephan Hartmann", time: "10:45"))
        ]
        
        print("\(entries)")
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct ScheduleWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 0){
            Text("Jetzt:").fontWeight(Font.Weight.bold).frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 20))
            HStack(spacing: 0){
                Text(entry.currentLesson.lessonName).font(.system(size: 17)).minimumScaleFactor(0.01).lineLimit(1)
                Spacer()
                Text(entry.currentLesson.room).font(.system(size: 17)).bold()
            }
            Text(entry.currentLesson.teacher).font(.system(size: 15)).minimumScaleFactor(0.01).lineLimit(1)
            
            Spacer()
                    .frame(height: 5)
            Text("Um \(entry.nextLesson.time):").fontWeight(Font.Weight.bold).frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 20))
            HStack(spacing:0){
                Text(entry.nextLesson.lessonName    ).font(.system(size: 17)).minimumScaleFactor(0.01).lineLimit(1)
                Spacer()
                Text(entry.nextLesson.room).font(.system(size: 17)).bold()
            }
            Text(entry.nextLesson.teacher).font(.system(size: 15)).minimumScaleFactor(0.01).lineLimit(1)
        }.padding(12.0)
    }
}

@main
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
