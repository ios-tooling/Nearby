//
//  TestingHarnessApp.swift
//  TestingHarness
//
//  Created by Ben Gottlieb on 1/21/25.
//  Copyright © 2025 Stand Alone, inc. All rights reserved.
//

import SwiftUI

@main
struct TestingHarnessApp: App {
	init() {
		Task { await Manager.instance.setup() }
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
