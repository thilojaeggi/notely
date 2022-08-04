//
//  GradeWidget.swift
//  GradeWidget
//
//  Created by Thilo Jaeggi on 2.8.2022.
//

import WidgetKit
import SwiftUI
import Intents

struct FlutterData: Decodable, Hashable {
    var grades: [String: Double] = [:]
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let flutterData: FlutterData?
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), flutterData: FlutterData(grades: ["MATH": 4.5,
                                                                    "SPOR": 5.0,
                                                                    "DEUT": 4.5,
                                                                    "PHYS": 4.5,
                                                                    "M126": 3.0,
                                                                    "ENGL": 5.5,
                                                                    "M128": 5.5,]))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), flutterData: FlutterData(grades: ["MATH": 4.5,
                                                                                "SPOR": 5.0,
                                                                                "DEUT": 4.5,
                                                                                "PHYS": 4.5,
                                                                                "M126": 3.0,
                                                                                "ENGL": 5.5,
                                                                                "M128": 5.5,]))
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        let sharedDefaults = UserDefaults.init(suiteName: "group.com.fasky")
        var flutterData: FlutterData? = nil
        
        if(sharedDefaults != nil) {
            do {
              let shared = sharedDefaults?.string(forKey: "widgetData")
              if(shared != nil){
                let decoder = JSONDecoder()
                flutterData = try decoder.decode(FlutterData.self, from: shared!.data(using: .utf8)!)
              }
            } catch {
              print(error)
            }
        }

        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
        let entry = SimpleEntry(date: entryDate, flutterData: flutterData)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct GradeWidgetEntryView : View {
    var entry: Provider.Entry
    var columns = [
            GridItem(alignment: .center),
            GridItem(alignment: .center),
            GridItem(alignment: .center),
            GridItem(alignment: .center),
            GridItem(alignment: .center),
            GridItem(alignment: .center),
        ]
        var body: some View {
            LazyVGrid(columns: columns, spacing: 0.5) {
                ForEach(entry.flutterData!.grades.sorted(by: >), id: \.key) { key, value in
                    VStack{
                        Text(key)
                        Text(String(value))
                    }
                }
            }
        }
}


@main
struct GradeWidget: Widget {
    let kind: String = "GradeWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            GradeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Durchschnitts Widget")
        .description("Zeigt pro Fach deinen Durchschnitt an.")
        .supportedFamilies([.systemMedium])

    }
}

struct GradeWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {

            GradeWidgetEntryView(entry: SimpleEntry(date: Date(), flutterData: FlutterData.init(grades: ["MATH": 4.5,
                                                                                                         "SPOR": 5.0,
                                                                                                         "DEUT": 4.5,
                                                                                                         "PHYS": 4.5,
                                                                                                         "M126": 3.0,
                                                                                                         "ENGL": 5.5,
                                                                                                         "M128": 5.5,])))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            
        }
    }
}
