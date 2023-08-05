//
//  NearbyDeviceCollection.swift
//  EyeFull
//
//  Created by Ben Gottlieb on 8/5/23.
//

import Foundation

public class NearbyDeviceCollection: ObservableObject {
	let filter: (NearbyDevice) -> Bool
	
	public var devices: [NearbyDevice] { NearbySession.instance.devices.values.filter { filter($0) } }
	
	init(filter: NearbyDevice.State) {
		self.filter = { $0.matches(filter: filter) }
	}
	
	init(predicate: @escaping (NearbyDevice) -> Bool) {
		self.filter = predicate
	}
	
	public var first: NearbyDevice? { devices.first }
	public var count: Int { devices.count }
}

extension NearbyDevice {
	func matches(filter: NearbyDevice.State) -> Bool {
		state.rawValue <= filter.rawValue
	}
}
