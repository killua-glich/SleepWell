//
//  SleepWellWidgetBundle.swift
//  SleepWellWidget
//
//  Created by diego on 20.05.26.
//

import WidgetKit
import SwiftUI

@main
struct SleepWellWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepWellWidget()
        SleepWellWidgetControl()
        SleepWellWidgetLiveActivity()
    }
}
