//
//  SpeedWidgetBundle.swift
//  SpeedWidget
//
//  Created by Justin Li on 2025/11/19.
//

import WidgetKit
import SwiftUI

@main
struct SpeedWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpeedWidget()
        SpeedWidgetControl()
        SpeedWidgetLiveActivity()
    }
}
