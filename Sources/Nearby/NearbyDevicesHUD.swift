//
//  File.swift
//  iOSTestingHarness
//
//  Created by Ben Gottlieb on 6/13/23.
//  Copyright © 2023 Stand Alone, inc. All rights reserved.
//

import SwiftUI
import CrossPlatformKit

extension Date {
	var secondAndNanosecond: String {
		let components = Calendar.current.dateComponents([.second, .nanosecond], from: self)
		
		return String(format: "%02d.%03d", components.second ?? 0, (components.nanosecond ?? 0) / 10_000)
	}
}

public struct NearbyDevicesHUD: View {
	@ObservedObject var session = NearbySession.instance
	@State var selectedDevice: NearbyDevice?
	@ObservedObject var history = MessageHistory.instance
	@AppStorage("show_simulators_in_nearby_hud") var showSimulators = true
	
	public init() { }
	
	var areSimulatorsPresent: Bool { session.devices.values.contains { $0.isSimulator }}
	var visibleDevices: [NearbyDevice] {
		if showSimulators { return session.devices.values.sorted() }
		
		return session.devices.values.filter { !$0.isSimulator }.sorted()
	}
	
	public var body: some View {
		VStack {
			ForEach(visibleDevices) { device in
				Button(action: { selectedDevice = device }) {
					DeviceRow(device: device)
				}
				.buttonStyle(.plain)
			}
			if areSimulatorsPresent {
				Toggle("Show Simulators", isOn: $showSimulators.animation())
					.padding(.horizontal)
			}
			
			ScrollView {
				VStack {
					ForEach(history.history) { item in
						HistoryCell(item: item)
					}
				}
				.font(.body)
			}
			Button("Clear Log") { history.clearHistory() }
		}
		.sheet(item: $selectedDevice) { device in NearbyDeviceDetailsView(device: device) }
	}
	
	struct HistoryCell: View {
		let item: MessageHistory.RecordedMessage
		
		var body: some View {
			HStack {
				HStack(spacing: 1) {
					Image(systemName: item.incoming ? "arrow.down" : "arrow.up")
					Text(item.date.secondAndNanosecond)
				}
				.font(.caption)
				
				Text(item.sender.displayName)
				Text(item.label)
				Spacer()
			}
			.opacity(item.incoming ? 1 : 0.5)
		}
	}
	
	struct DeviceRow: View {
		@ObservedObject var device: NearbyDevice
		
		var body: some View {
			HStack(spacing: 2) {
				Image(systemName: device.imageName)
					.foregroundColor(Color(uxColor: device.stateColor))
					.padding(.horizontal, 4)
				
				Text(device.displayName)
				if let info = device.deviceInfo, !info.isEmpty {
					Text("{\(info.count)}")
				}
				if device.isSimulator { Text("[sim]") }
			}
		}
	}
}
