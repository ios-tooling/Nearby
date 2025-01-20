//
//  HarnessMainView.swift
//  iOSTestingHarness
//
//  Created by Ben Gottlieb on 1/19/25.
//  Copyright © 2025 Stand Alone, inc. All rights reserved.
//

import SwiftUI

struct HarnessMainView: View {
	@ObservedObject var nearbySession = NearbySession.instance
	var body: some View {
		VStack {
			let devices = Array(nearbySession.devices.cachedDevices).sorted(by: { $0.displayName < $1.displayName })
			
			ForEach(devices) { device in
				DeviceRow(device: device)
			}
			Spacer()
			
		}
		.padding()
	}
	
	struct DeviceRow: View {
		@ObservedObject var device: NearbyDevice
		
		var body: some View {
			HStack {
				Text("\(device.displayName)")
				Spacer()
				Text("\(device.state)")
			}
		}
	}
}

#Preview {
	HarnessMainView()
}
