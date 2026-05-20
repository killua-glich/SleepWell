import SwiftUI

func timeString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm"
    return f.string(from: date)
}

func ampmString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "a"
    return f.string(from: date)
}

var widgetBackground: some View {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1c2e"), Color(hex: "12141f")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        RadialGradient(
            colors: [Color.accent.opacity(0.18), .clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: 120
        )
    }
}
