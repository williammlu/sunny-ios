import ActivityKit
import WidgetKit
import SwiftUI
import SunnyShared

@available(iOS 16.1, *)
struct SunnyLiveActivitiesLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunlightActivityAttributes.self) { context in
            // =======================
            // LOCK SCREEN VIEW
            // =======================
            let isComplete = context.state.isComplete
            let ringColor = isComplete ? Color.green : Color.orange
            
            ZStack {
                HStack {
                    // Left: sun emoji
                    Text("☀️")
                        .font(.title2)
                    
                    Spacer()
                    
                    // Center: app name or title
                    Text("Sunny")
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    // Right: Timer aligned to the right
                    Text("\(context.state.startDate, style: .timer)/15:00")
                        .font(.headline)
                        // Forces the text to align its contents (especially if it wraps)
                        .multilineTextAlignment(.trailing)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .background(ringColor)
            .cornerRadius(12)
            .activityBackgroundTint(ringColor)
            .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            // =======================
            // DYNAMIC ISLAND LAYOUT
            // =======================
            let isComplete = context.state.isComplete
            let ringColor = isComplete ? Color.green : Color.orange
            
            return DynamicIsland {
                // Expanded region: simple layout with the timer on the left, sun on the right
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 8) {
                        // Timer text, with a bit of left padding
                        Text("\(context.state.startDate, style: .timer)/15:00")
                            .font(.headline)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        // Sun emoji
                        Text("☀️")
                            .font(.headline)
                    }
                }
            } compactLeading: {
                // Show [timer]/15:00 in orange with a small left padding
                Text("\(context.state.startDate, style: .timer)/15:00")
                    .foregroundColor(.orange)
                    .font(.caption2)
                    .padding(.leading, 4)
            } compactTrailing: {
                // Sun emoji on the right
                Text("☀️")
                    .font(.caption2)
            } minimal: {
                // Minimal: just the sun
                Text("☀️")
                    .font(.caption2)
            }
            .widgetURL(URL(string: "sunny://continueSession"))
            .keylineTint(ringColor)
        }
    }
}
