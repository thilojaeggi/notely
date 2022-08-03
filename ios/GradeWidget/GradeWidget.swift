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
    let text: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let flutterData: FlutterData?
}
let column = Array(repeating: GridItem(.flexible()), count: 3);

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), flutterData: FlutterData(text: "Hello from Flutter"))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), flutterData: FlutterData(text: "Hello from Flutter"))
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
    
    private var FlutterDataView: some View {
        List {
                   Text("Test 1")                .foregroundColor(Color.white)

            Text("Test 2")
                .foregroundColor(Color.white)
               }
    }
    
    private var NoDataView: some View {
        VStack{
            Spacer()

            LazyVGrid(columns: column, alignment: .center, spacing: 5) {
                VStack{
                    Text("Fra")
                    Text("4.0")
                }
                VStack{
                    Text("Fra")
                    Text("4.0")
                }
                VStack{
                    Text("Fra")
                    Text("4.0")
                }
                VStack{
                    Text("Fra")
                    Text("4.0")
                }
                VStack{
                    Text("Fra")
                    Text("4.0")
                }
                VStack{
                    Text("Fra")
                    Text("4.0")
                }
                VStack{
                    Text("Fra")
                    Text("4.0")
                }
                

            }
            Spacer()

        }
            

        


    }
    
    var body: some View {
        
        VStack{
            Spacer()
            if(entry.flutterData == nil) {
              NoDataView
            } else {
              FlutterDataView
            }
            Spacer()
            Divider()
        }.background(Color.black.opacity(0.9)).foregroundColor(Color.white).overlay(
            RoundedRectangle(cornerRadius: 17)
                .stroke(.white, lineWidth: 2).padding(.all, 5.0)
        )
      
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
    }
}

struct GradeWidget_Previews: PreviewProvider {
    static var previews: some View {
        GradeWidgetEntryView(entry: SimpleEntry(date: Date(), flutterData: nil))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
    }
}
