//
//  SpeedWidgetLiveActivity.swift
//  SpeedWidget
//
//  Created by Justin Li on 2025/11/19.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Import the shared attributes from the main app
@available(iOS 16.1, *)
struct SpeedActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var speed: String
    }
}

@available(iOS 16.1, *)
struct SpeedWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpeedActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack(spacing: 16) {
                // Speed icon
                Image(systemName: "speedometer")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Speed")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(context.state.speed)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                
                Spacer()
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - shows detailed speed information
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "speedometer")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Speed")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(context.state.speed)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundStyle(.white.opacity(0.6))
                        Text("DriveAgent")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("Tracking...")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact leading - speedometer icon
                Image(systemName: "speedometer")
                    .foregroundStyle(.white)
            } compactTrailing: {
                // Compact trailing - just the speed number
                Text(extractSpeedNumber(from: context.state.speed))
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundStyle(.white)
            } minimal: {
                // Minimal - just a speedometer icon
                Image(systemName: "speedometer")
                    .foregroundStyle(.white)
            }
            .keylineTint(Color.blue)
        }
    }
    
    // Helper function to extract just the number from "XX km/h" or "XX mph"
    private func extractSpeedNumber(from speedString: String) -> String {
        let components = speedString.components(separatedBy: " ")
        return components.first ?? "0"
    }
}

// Preview support
extension SpeedActivityAttributes {
    fileprivate static var preview: SpeedActivityAttributes {
        SpeedActivityAttributes()
    }
}

extension SpeedActivityAttributes.ContentState {
    fileprivate static var slow: SpeedActivityAttributes.ContentState {
        SpeedActivityAttributes.ContentState(speed: "25 km/h")
    }
    
    fileprivate static var fast: SpeedActivityAttributes.ContentState {
        SpeedActivityAttributes.ContentState(speed: "80 km/h")
    }
    
    fileprivate static var stopped: SpeedActivityAttributes.ContentState {
        SpeedActivityAttributes.ContentState(speed: "0 km/h")
    }
}

#Preview("Notification", as: .content, using: SpeedActivityAttributes.preview) {
   SpeedWidgetLiveActivity()
} contentStates: {
    SpeedActivityAttributes.ContentState.slow
    SpeedActivityAttributes.ContentState.fast
    SpeedActivityAttributes.ContentState.stopped
}
