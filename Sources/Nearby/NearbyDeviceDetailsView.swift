//
//  NearbyDeviceDetailsView.swift
//
//
//  Created by Ben Gottlieb on 6/14/23.
//

import SwiftUI

public struct NearbyDeviceDetailsView: View {
	@ObservedObject var device: NearbyDevice
	@Environment(\.dismiss) var dismiss
	
	public init(device: NearbyDevice) {
		self.device = device
	}
	
	public var body: some View {
		VStack(alignment: .leading) {
			ZStack {
				Text("Device Details").bold()
				Button("Done") { dismiss() }
					.frame(maxWidth: .infinity, alignment: .trailing)
					.padding()
			}
			ScrollView {
				VStack {
					Text("State: \(device.state.description)")
					Text("MCState: \(device.lastReceivedSessionState.description)")
					Text("PeerID: \(device.session?.myPeerID.description ?? "--")")
					Text("Last seen at: \(device.lastSeenAt.localTimeString(date: .none))")
					if let lastConnectedAt = device.lastConnectedAt {
						Text("Last connected at: \(lastConnectedAt.localTimeString(date: .none))")
					}
					Divider()
					
					if let info = device.discoveryInfo, !info.isEmpty {
						Text("Discovery Info").font(.caption)
						
						let keys = Array(info.keys)
						ForEach(keys.indices, id: \.self) { index in
							let key = keys[index]
							Text("\(key): \(info[key] ?? "--")")
						}
						Divider()
					}
					
					if let info = device.deviceInfo, !info.isEmpty {
						Text("Device Info").font(.caption)
						
						let keys = Array(info.keys)
						ForEach(keys.indices, id: \.self) { index in
							let key = keys[index]
							Text("\(key): \(info[key] ?? "--")")
						}
						Divider()
					}
					
					Spacer()
				}
				.padding()
			}
			
			HStack {
				if device.state.isConnected {
					Button("Disconnect", role: .destructive) { device.disconnectFromPeers() }
						.padding()
				} else if device.state == .connecting {
					HStack {
						Text("Connecting…")
							.opacity(0.5)
						ProgressView()
					}
				} else {
					Button("Connect") { device.connect() }
						.padding()
				}
				
				Spacer()
				
				if device.state.isConnected {
					Button("Refresh Info") {
						device.requestInfo()
						device.requestAvatar()
					}
					.padding()
				}
			}
		}
	}
}
