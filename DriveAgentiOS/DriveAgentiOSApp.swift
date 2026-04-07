//
//  DriveAgentiOSApp.swift
//  DriveAgentiOS
//
//  Created by Justin Li on 2025/11/19.
//

import SwiftUI

@main
struct DriveAgentiOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
//                .onOpenURL { url in
//                    _ = SpotifyManager.shared.handleURL(url)
//                }
        }
//        .onChange(of: scenePhase) { oldPhase, newPhase in
//            switch newPhase {
//            case .active:
//                SpotifyManager.shared.connect()
//            case .background:
//                SpotifyManager.shared.disconnect()
//            default:
//                break
//            }
//        }
    }
}
