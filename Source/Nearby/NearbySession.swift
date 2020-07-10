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
	public var application: UXApplication!
	public var serviceType: String! { didSet { assert(self.serviceType.count <= 15, "Your serviceType string is longer than 15 characters.") }}
	public var alwaysRequestInfo = true
	static public var deviceClass = NearbyDevice.self

	public var peerID: MCPeerID { return NearbyDevice.localDevice.peerID }
	public var devices: [Int: NearbyDevice] = [:] { didSet { self.sendChanges() }}
	
	public var connectedDevices: [NearbyDevice] { return self.devices.values.filter { $0.state == .connected }}
}

extension NearbySession {
	func sendChanges() {
		if #available(OSX 10.15, iOS 13.0, *) {
			#if canImport(Combine)
				self.objectWillChange.send()
			#endif
		}
	}
	
	public struct Notifications {
		public static let didStartUp = Notification.Name("session-didStartUp")
		public static let didShutDown = Notification.Name("session-didShutDown")
	}
	
	func broadcastDeviceInfoChange() {
		NearbySession.instance.sendToAll(message: NearbySystemMessage.DeviceInfo())
	}
	
	open func sendToAll<MessageType: NearbyMessage>(message: MessageType) {
		Logger.instance.log("Sending \(message.command) as a \(type(of: message)) to all")
		let payload = NearbyMessagePayload(message: message)
		for device in self.connectedDevices {
			device.send(payload: payload)
		}
	}
}

extension NearbySession {
	public func startup(withRouter: NearbyMessageRouter? = nil, application: UXApplication? = nil) {
		if let router = withRouter { self.messageRouter = router }
		if let app = application { self.application = app }

		
		assert(self.application != nil, "You must set a UXApplication before starting a NearbySession.")
		assert(self.serviceType != nil, "You must set a serviceType before starting a NearbySession.")

		if self.isActive { return }
		self.isActive = true
		self.isShuttingDown = false
		self.devices = [:]
		self.locateDevice()
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.didStartUp, object: self)}
	}
	
	public func shutdown() {
		Logger.instance.log("Shutting Down: \(peerID.displayName)")
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
		if let app = self.application { self.startup(withRouter: self.messageRouter, application: app) }
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
		self.devices[device.peerID.hashValue] = device
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
