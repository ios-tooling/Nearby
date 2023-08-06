//
//  NearbyDeviceCollection.swift
//  EyeFull
//
//  Created by Ben Gottlieb on 8/5/23.
//

import Foundation

public class NearbyDeviceCollection: ObservableObject {
	let filter: (NearbyDevice) -> Bool
	let label: String
	var lastHash = 0
	public var devices: [NearbyDevice] = []
	
	var computedDevices: [NearbyDevice] { NearbySession.instance.devices.values.filter { filter($0) } }
	
	init(label: String, filter: NearbyDevice.State) {
		self.filter = { $0.matches(filter: filter) }
		self.label = label
	}
	
	init(label: String, predicate: @escaping (NearbyDevice) -> Bool) {
		self.filter = predicate
		self.label = label
	}
	
	public var first: NearbyDevice? { devices.first }
	public var count: Int { devices.count }
	
	func update() {
		let newDevices = computedDevices
		
		if newDevices != devices {
			devices = newDevices
			objectWillChange.send()
		}
				
//		if label == "Provisioned" {
//			let d = devices
//			print("--------------------------")
//			print("\(label) devices changed, have \(count)/\(d.count) now \(d)")
//			print(NearbySession.instance.devices.values)
//			print("--------------------------")
//		}
	}
}

extension NearbyDevice {
	func matches(filter: NearbyDevice.State) -> Bool {
		isVisible && state.rawValue >= filter.rawValue
	}
}
