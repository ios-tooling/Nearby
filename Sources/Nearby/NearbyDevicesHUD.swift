//
//  File.swift
//  iOSTestingHarness
//
//  Created by Ben Gottlieb on 6/13/23.
//  Copyright © 2023 Stand Alone, inc. All rights reserved.
//

import SwiftUI

public struct NearbyDevicesHUD: View {
	@ObservedObject var session = NearbySession.instance
	
	public init() { }
	
	public var body: some View {
		VStack {
			ForEach(session.devices.values.sorted()) { device in
				HStack {
					Image(systemName: device.imageName)
					
					Text(device.idiom)
					Text(device.displayName)
				}
			}
		}
	}
}
