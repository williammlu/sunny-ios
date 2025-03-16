import ActivityKit
import WidgetKit
import SwiftUI
import SunnyShared // or wherever you define SunlightActivityAttributes

@available(iOS 16.1, *)
struct SunnyLiveActivitiesLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunlightActivityAttributes.self) { context in
            // ================
            // LOCK SCREEN VIEW
            // ================
            
            let totalGoal = 15
            let elapsedSeconds = context.state.elapsedSeconds
            let fraction = Double(elapsedSeconds) / Double(totalGoal * 60)
            let clamped = min(1.0, fraction)
            
            // Convert to min/sec for the extra line
            let elapsedMinutes = elapsedSeconds / 60
            let secondsRemaining = elapsedSeconds % 60
            
            // A more open layout with bigger spacing/padding
            HStack(spacing: 16) {
                // Left icon (yellow sun)
                Image(systemName: "sun.max.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.yellow)
                
                // Right side: Title "Sunny" + progress + second line
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text("Sunny")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Second line: "Xm Ys/15m completed"
                    Text("\(elapsedMinutes)m \(secondsRemaining)s / \(totalGoal)m completed")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    // A simple horizontal progress bar
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 6)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 120 * CGFloat(clamped), height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16) // more padding around everything
            .background(Color.orange)
            .cornerRadius(12)
            .activityBackgroundTint(Color.orange)
            .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            // =======================
            // DYNAMIC ISLAND LAYOUT
            // =======================
            
            let totalGoal = 15
            let elapsedSeconds = context.state.elapsedSeconds
            let elapsedMinutes = elapsedSeconds / 60
            let secondsRemaining = elapsedSeconds % 60
            
            return DynamicIsland {
                // EXPANDED REGION:
                DynamicIslandExpandedRegion(.center) {
                    // Show only “Xm Ys/15m” plus a sun emoji
                    HStack(spacing: 8) {
                        Text("☀️")
                        Text("\(elapsedMinutes)m \(secondsRemaining)s/\(totalGoal)m")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                }
                
            } compactLeading: {
                // Add some right padding so ring doesn't clip camera
                let fraction = Double(elapsedSeconds) / Double(totalGoal * 60)
                
                ZStack {
                    // Orange ring
                    Circle()
                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                    
                    Circle()
                        .trim(from: 0.0, to: min(fraction, 1.0))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    // Put the sun icon in the center
                    Text("☀️")
                        .font(.caption)
                }
                .frame(width: 24, height: 24)
                .padding(.trailing, 8) // extra trailing space
            } compactTrailing: {
                // We keep this empty
                EmptyView()
            } minimal: {
                // Minimal => Just a ring with sun
                let fraction = Double(elapsedSeconds) / Double(totalGoal * 60)
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                    Circle()
                        .trim(from: 0.0, to: min(fraction, 1.0))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("☀️")
                        .font(.caption2)
                }
                .frame(width: 18, height: 18)
            }
            .widgetURL(URL(string: "sunny://continueSession"))
            .keylineTint(Color.orange)
        }
    }
}

// OPTIONAL: If you want a purely clockwise spinning sun in some region:
// (Here we keep it out of the lock screen for clarity, but you can
// incorporate it if you wish.)
struct FixedSpinningSunView: View {
    let elapsedSeconds: Int
    
    var body: some View {
        // Use TimelineView to update every second
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            // We'll spin at 360° every 10 real seconds
            let date = context.date.timeIntervalSince1970
            let fraction = (date.truncatingRemainder(dividingBy: 10)) / 10.0
            let angle = 360.0 * fraction // purely forward
            
            Image(systemName: "sun.max.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.yellow)
                .rotationEffect(.degrees(angle))
        }
    }
}
