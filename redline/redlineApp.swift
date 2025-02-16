//
//  redlineApp.swift
//  redline
//
//  Created by Yang Gao on 2/14/25.
//

import SwiftUI
import TerraiOS

@main
struct redlineApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView(modelName: "Particle_Wave")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Terra.setUpBackgroundDelivery()
        return true
    }
}
