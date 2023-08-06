//
//  NearbySession.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit
import Studio

#if canImport(Combine)
import SwiftUI

@available(OSX 10.15, iOS 13.0, *)
extension NearbySession: ObservableObject {
	
}
#endif

public class NearbySession: NSObject {
	public static let instance = NearbySession()
	
	var deviceLocator: NearbyScanner!
	public var localDeviceInfo: [String: String] = [:] { didSet {
		if self.localDeviceInfo != oldValue { self.broadcastDeviceInfoChange() }
	}}
	public var isShuttingDown = false
	public var isActive = false { didSet { self.sendChanges() }}
	public var useEncryption = false
	public var messageRouter: NearbyMessageRouter?
	public var application: UXApplication?
	public var serviceType: String! { didSet { try! serviceType.validateBonjourServiceType() }}
	public var alwaysRequestInfo = true
	public var localDeviceName = Gestalt.deviceName { didSet { NearbyDevice.localDevice.updateDiscoveryInfo() }}
	public var disconnectDisappearInterval: TimeInterval? = 5
	static public var deviceClass = NearbyDevice.self

	public var peerID: MCPeerID { return NearbyDevice.localDevice.peerID }
	public private(set) var devices: [Int: NearbyDevice] = [:]
	public func enableLogging(on: Bool) {
		MessageHistory.instance.limit = on ? 100 : 0
	}
	
	public var disconnectTimer: Timer?
	public var connectedDevices = NearbyDeviceCollection(label: "Connected", filter: .connected)
	public var visibleDevices = NearbyDeviceCollection(label: "Visible") { device in device.isVisible }
	public var provisionedDevices = NearbyDeviceCollection(label: "Provisioned", filter: .provisioned)
	
	func updateCollections(for device: NearbyDevice) {
		connectedDevices.update()
		visibleDevices.update()
		provisionedDevices.update()
	}
}

extension NearbySession {
	func sendChanges() {
		self.objectWillChange.send()
	}
	
	public struct Notifications {
		public static let didStartUp = Notification.Name("session-didStartUp")
		public static let didShutDown = Notification.Name("session-didShutDown")
	}
	
	func broadcastDeviceInfoChange() {
		NearbySession.instance.sendToAll(message: NearbySystemMessage.DeviceInfo())
	}
	
	public func sendToAll<MessageType: NearbyMessage>(message: MessageType?) {
		guard let message else { return }
		NearbyLogger.instance.log("Sending \(message.command) as a \(type(of: message)) to all", onlyWhenDebugging: true)
		let payload = NearbyMessagePayload(message: message)
		for device in self.connectedDevices.devices {
			device.send(payload: payload)
		}
	}
}

extension NearbySession {
	public func cycle() {
		if !isActive { return }
		shutdown()
		DispatchQueue.main.async(after: 1.0) {
			self.startup()
		}
	}
	
	@MainActor func updateDisconnectTimer() {
		guard let disconnectDisappearInterval else { return }
		var minTime = disconnectDisappearInterval + 1
		
		for device in devices.values {
			if device.state != .hidden, let time = device.disconnectedAt?.timeIntervalSinceNow, abs(time) < disconnectDisappearInterval, abs(time) < minTime { minTime = abs(time) }
		}
		
		if minTime < disconnectDisappearInterval {
			disconnectTimer = Timer.scheduledTimer(withTimeInterval: (disconnectDisappearInterval - minTime) + 1, repeats: false) { _ in
				self.hideDisconnectedDevices()
			}
		}
	}
	
	func hideDisconnectedDevices() {
		guard let disconnectDisappearInterval else { return }

		for device in devices.values {
			if device.state != .hidden, let time = device.disconnectedAt?.timeIntervalSinceNow, abs(time) >= disconnectDisappearInterval {
				device.state = .hidden
			}
		}
		
		withAnimation {
			objectWillChange.send()
		}
	}

	public func
	startup(withRouter: NearbyMessageRouter? = nil, application: UXApplication? = nil) {
		assert(serviceType != nil, "You must set a serviceType first.")
		try! serviceType.validateBonjourServiceType()
		
		if let router = withRouter { self.messageRouter = router }
		if let app = application { self.application = app }

		
	//	assert(self.application != nil, "You must set a UXApplication before starting a NearbySession.")
		assert(self.serviceType != nil, "You must set a serviceType before starting a NearbySession.")

		if self.isActive { return }
		self.isActive = true
		self.isShuttingDown = false
		self.devices = [:]
		self.locateDevice()
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.didStartUp, object: self)}
	}
	
	public func shutdown() {
		NearbyLogger.instance.log("Shutting Down: \(peerID.displayName)", onlyWhenDebugging: true)
		if !self.isActive || self.isShuttingDown { return }
		self.isActive = false
		self.isShuttingDown = true
		self.deviceLocator?.stopLocating()
		self.deviceLocator = nil
		for device in self.devices.values {
			device.state = .none
		}
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.didShutDown, object: self)}
	}
	
	@objc func didEnterBackground() {
		self.shutdown()
	}
	
	@objc func willEnterForeground() {
		self.startup(withRouter: self.messageRouter, application: application)
	}
	
	public func locateDevice() {
		if self.deviceLocator != nil { return }			//already locating
		
		self.deviceLocator = NearbyScanner(delegate: self)
		self.deviceLocator?.startLocating()
	}
	
	func uniqueDisplayName(from name: String) -> String {
		var count = name == self.peerID.displayName ? 1 : 0
		var current = name + (count == 0 ? "" : " - \(count)")
		var nameExists = false
		
		repeat {
			nameExists = false
			for device in self.devices.values {
				if device.displayName == current {
					count += 1
					current = name + " - \(count)"
					nameExists = true
				}
			}
		} while nameExists
		
		return current
	}
}

extension NearbySession: DeviceLocatorDelegate {
	func didLocate(device: NearbyDevice) {
		DispatchQueue.main.async {
			self.devices[device.peerID.hashValue] = device
			self.messageRouter?.didDiscover(device: device)

			withAnimation {
				self.objectWillChange.send()
			}
		}
	}
	
	func didFailToLocateDevice() {
		self.deviceLocator?.stopLocating()
	}
	
	func device(for peerID: MCPeerID) -> NearbyDevice? {
		if let device = self.devices[peerID.hashValue] {
			return device
		}
		
		return nil
	}

}
