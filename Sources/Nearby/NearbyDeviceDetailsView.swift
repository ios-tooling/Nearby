//
//  NearbyDeviceDetailsView.swift
//
//
//  Created by Ben Gottlieb on 6/14/23.
//

import SwiftUI

public struct NearbyDeviceDetailsView: View {
	@ObservedObject var device: NearbyDevice
	
	public init(device: NearbyDevice) {
		self.device = device
	}
	
	public var body: some View {
		VStack(alignment: .leading) {
			Text("State: \(device.state.description)")
			Text("MCState: \(device.lastReceivedSessionState.description)")
			Divider()
			
			if let info = device.discoveryInfo, !info.isEmpty {
				Text("Discovery Info").font(.caption)
				
				let keys = Array(info.keys)
				ForEach(keys.indices, id: \.self) { index in
					let key = keys[index]
					Text("\(key): \(info[key] ?? "--")")
				}
				Divider()
				
				if let connected = device.session?.connectedPeers {
					Text("Connected Peers").font(.caption)
					ForEach(connected.indices, id: \.self) { index in
						Text("\(connected[index].displayName)")
					}
					Divider()
				}
				
				if device.state == .connected {
					Button("Disconnect", role: .destructive) { device.disconnectFromPeers() }
				} else {
					Button("Connect") { device.connect() }
				}
			}
		}
		.padding()
	}
}
