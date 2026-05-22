import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SleepWellWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepWellWidget()
        BedtimeCountdownLiveActivity()
    }
}
