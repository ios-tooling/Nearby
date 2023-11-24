//
//  NearbyDeviceCollection.swift
//  EyeFull
//
//  Created by Ben Gottlieb on 8/5/23.
//

import Foundation
import MultipeerConnectivity
import Combine

public actor NearbyDeviceCollection: ObservableObject {
	let filter: ((NearbyDevice) -> Bool)?
	let label: String
	var lastHash = 0
	public var cachedDevices: [NearbyDevice] = []
	nonisolated let currentDevices = CurrentValueSubject<[NearbyDevice], Never>([])
	
	var computedDevices: [NearbyDevice] {
		get async {
			guard let filter else { return cachedDevices }
			let all = await NearbySession.instance.devices.computedDevices
			return all.filter { filter($0) }
		}
	}
	
	func clear() {
		cachedDevices = []
		currentDevices.send(cachedDevices)
	}
	
	func add(device: NearbyDevice) {
		if !cachedDevices.contains(where: { $0.peerID == device.peerID }) {
			cachedDevices.append(device)
			currentDevices.send(cachedDevices)
		}
	}
	
	func device(for peerID: MCPeerID) -> NearbyDevice? {
		cachedDevices.first { $0.peerID == peerID }
	}
	
	public nonisolated var devices: [NearbyDevice] { currentDevices.value }
	public nonisolated var count: Int { currentDevices.value.count }
	public nonisolated var first: NearbyDevice? { currentDevices.value.first }

	init(devices: [NearbyDevice]) {
		self.cachedDevices = devices
		self.label = ""
		self.filter = nil
	}
	
	init(label: String, filter: NearbyDevice.State) {
		self.filter = { $0.matches(filter: filter) }
		self.label = label
	}
	
	init(label: String, predicate: @escaping (NearbyDevice) -> Bool) {
		self.filter = predicate
		self.label = label
	}
	
//	public var count: Int { cachedDevices.count }
	
	func update() async {
		let newDevices = await computedDevices
		
		if newDevices != cachedDevices {
			cachedDevices = newDevices
			currentDevices.send(cachedDevices)
			await MainActor.run { objectWillChange.send() }
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
