//
//  DeviceContainer.swift
//
//
//  Created by Ben Gottlieb on 8/28/23.
//

import SwiftUI

struct DevicesEnvironmentKey: EnvironmentKey {
	static var defaultValue: [NearbyDevice] = []
}

public extension EnvironmentValues {
	var nearbyDevices: [NearbyDevice] {
		get { self[DevicesEnvironmentKey.self] }
		set { self[DevicesEnvironmentKey.self] = newValue }
	}
}

public struct DeviceContainer<Content: View>: View {
	@State private var devices: [NearbyDevice] = []
	@ObservedObject private var collection: NearbyDeviceCollection
	@ViewBuilder let content: ([NearbyDevice]) -> Content
	
	public init(_ collection: NearbyDeviceCollection, @ViewBuilder content: @escaping ([NearbyDevice]) -> Content) {
		self.content = content
		self.collection = collection
	}

	public init(_ collection: NearbyDeviceCollection, @ViewBuilder content: @escaping () -> Content) {
		self.content = { _ in content() }
		self.collection = collection
	}

	public var body: some View {
		content(devices)
			.onAppear { loadDevices() }
			.onReceive(collection.objectWillChange) { _ in loadDevices() }
			.environment(\.nearbyDevices, devices)
	}
	
	func loadDevices() {
		Task { @MainActor in
			devices = await collection.computedDevices
		}
	}
	
}

