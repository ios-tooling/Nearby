//
//  File.swift
//  iOSTestingHarness
//
//  Created by Ben Gottlieb on 6/13/23.
//  Copyright © 2023 Stand Alone, inc. All rights reserved.
//

import SwiftUI
import CrossPlatformKit

public struct NearbyDevicesHUD: View {
	@ObservedObject var session = NearbySession.instance
	@State var selectedDevice: NearbyDevice?
	
	public init() { }
	
	public var body: some View {
		VStack {
			ForEach(session.devices.values.sorted()) { device in
				Button(action: { selectedDevice = device }) {
					DeviceRow(device: device)
				}
				.buttonStyle(.plain)
			}
		}
		.sheet(item: $selectedDevice) { device in NearbyDeviceDetailsView(device: device) }
	}
	
	struct DeviceRow: View {
		@ObservedObject var device: NearbyDevice
		
		var body: some View {
			HStack {
				Image(systemName: device.imageName)
					.foregroundColor(Color(uxColor: device.state.color))
				
				Text(device.displayName)
			}
		}
	}
}
