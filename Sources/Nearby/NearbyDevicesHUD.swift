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
	
	public init() { }
	
	public var body: some View {
		VStack {
			ForEach(session.devices.values.sorted()) { device in
				DeviceRow(device: device)
			}
		}
	}
	
	struct DeviceRow: View {
		@ObservedObject var device: NearbyDevice
		
		var body: some View {
			HStack {
				Image(systemName: device.imageName)
					.foregroundColor(Color(uxColor: device.state.color))
				
				Text(device.idiom)
				Text(device.displayName)
			}
		}
	}
}
