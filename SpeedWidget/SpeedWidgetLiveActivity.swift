//
//  SpeedWidgetLiveActivity.swift
//  SpeedWidget
//
//  Created by Justin Li on 2025/11/19.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SpeedWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SpeedWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpeedWidgetAttributes.self) { context in
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

extension SpeedWidgetAttributes {
    fileprivate static var preview: SpeedWidgetAttributes {
        SpeedWidgetAttributes(name: "World")
    }
}

extension SpeedWidgetAttributes.ContentState {
    fileprivate static var smiley: SpeedWidgetAttributes.ContentState {
        SpeedWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SpeedWidgetAttributes.ContentState {
         SpeedWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SpeedWidgetAttributes.preview) {
   SpeedWidgetLiveActivity()
} contentStates: {
    SpeedWidgetAttributes.ContentState.smiley
    SpeedWidgetAttributes.ContentState.starEyes
}
