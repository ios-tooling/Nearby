//
//  Manager.swift
//  TestingHarness
//
//  Created by Ben Gottlieb on 1/21/25.
//  Copyright © 2025 Stand Alone, inc. All rights reserved.
//

import Foundation
import CrossPlatformKit


actor Manager {
	static let instance = Manager()
	var scanner: NearbyScanner!
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(discoveredDevice), name: NearbyDevice.Notifications.deviceConnected, object: nil)
		
		NearbySession.instance.serviceType = "Nearby-test"
		Task {
			await NearbySession.instance.startup(application: UXApplication.shared)
			NearbySession.instance.localDeviceInfo = ["Goodbye": "There"]
		}
		
	}
	
	func setup() {
		scanner = NearbyScanner(delegate: self)
		scanner.startLocating()
	}
	
	@objc nonisolated func discoveredDevice(note: Notification) {
		guard let device = note.object as? NearbyDevice else { return }
		
		print("Device discovered: \(device.name)")
	}
}

extension Manager: DeviceLocatorDelegate {
	nonisolated func didLocate(device: NearbyDevice) {
		print("Located \(device.name)")
	}
	
	nonisolated func didFailToLocateDevice() {
		print("Failed to locate a device.")
	}

}
