//
//  WordGolfApp_iOS.swift
//  WordGolf-iOS
//
//  Main application entry point for iOS
//

import SwiftUI
import WordGolfCore

@main
struct WordGolfApp_iOS: App {
    @StateObject private var gameModel = GameModel()

    var body: some Scene {
        WindowGroup {
            ContentView_iOS()
                .environmentObject(gameModel)
        }
    }
}
