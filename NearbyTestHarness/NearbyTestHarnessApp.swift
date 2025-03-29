//
//  NearbyTestHarnessApp.swift
//  NearbyTestHarness
//
//  Created by Ben Gottlieb on 3/24/25.
//

import SwiftUI
import Nearby

@main
struct NearbyTestHarnessApp: App {
	init() {
		Task {
			await NearbySession.setup()
		}
	}
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
