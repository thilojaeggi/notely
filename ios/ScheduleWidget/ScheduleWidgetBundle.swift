//
//  ScheduleWidgetBundle.swift
//  ScheduleWidget
//
//  Created by Thilo on 24.11.2025.
//

import WidgetKit
import SwiftUI

@main
struct ScheduleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScheduleWidget()
        ScheduleWidgetControl()
        ScheduleWidgetLiveActivity()
    }
}
