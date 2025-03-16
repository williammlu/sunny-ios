//
//  SunnyLiveActivitiesLiveActivity.swift
//  SunnyLiveActivities
//
//  Created by William Lu on 3/15/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SunnyLiveActivitiesAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SunnyLiveActivitiesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunnyLiveActivitiesAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SunnyLiveActivitiesAttributes {
    fileprivate static var preview: SunnyLiveActivitiesAttributes {
        SunnyLiveActivitiesAttributes(name: "World")
    }
}

extension SunnyLiveActivitiesAttributes.ContentState {
    fileprivate static var smiley: SunnyLiveActivitiesAttributes.ContentState {
        SunnyLiveActivitiesAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SunnyLiveActivitiesAttributes.ContentState {
         SunnyLiveActivitiesAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SunnyLiveActivitiesAttributes.preview) {
   SunnyLiveActivitiesLiveActivity()
} contentStates: {
    SunnyLiveActivitiesAttributes.ContentState.smiley
    SunnyLiveActivitiesAttributes.ContentState.starEyes
}
