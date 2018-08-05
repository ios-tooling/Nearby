//
//  DeviceSession.swift
//  SpotEm
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public class PeerSession: NSObject {
	public struct Notifications {
		public static let didStartUp = Notification.Name("session-didStartUp")
		public static let didShutDown = Notification.Name("session-didShutDown")
	}
	
	public static let instance = PeerSession()
	
	var deviceLocator: PeerScanner!
//	var session: MCSession!
	public var isShuttingDown = false
	public var isActive = false
	public var messageRouter: PeerMessageRouter?
	public var application: UIApplication!
	
	public var peerID: MCPeerID { return PeerDevice.localDevice.peerID }
	public var devices: [MCPeerID: PeerDevice] = [:]
	
	override init() {
		super.init()
		
		NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
	}
	
	var connectedDevices: [PeerDevice] { return self.devices.values.filter { $0.state == .connected }}
	
	func checkForLostSession() {
//		if !self.isShuttingDown, self.connectedDevices.isEmpty {
//			Logger.instance.log("No devices found, resetting session")
//			self.shutdown()
//			Dispatcher.main.wait(2.5) {
//				self.startup()
//			}
//		}
	}
}

extension PeerSession {
	public func startup(withRouter: PeerMessageRouter? = nil, application: UIApplication? = nil) {
		if let router = withRouter { self.messageRouter = router }
		if let app = application { self.application = app }

		
		assert(self.messageRouter != nil, "You must set a message router before starting a PeerSession.")
		assert(self.application != nil, "You must set a UIApplication before starting a PeerSession.")

		if self.isActive { return }
		self.isActive = true
		self.isShuttingDown = false
		self.devices = [:]
//		self.session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
//		self.session.delegate = self
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
//		self.session.disconnect()
//		self.session = nil
		for device in self.devices.values {
			device.state = .none
		}
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.didShutDown, object: self)}
	}
	
	@objc func didEnterBackground() {
		self.shutdown()
	}
	
	@objc func willEnterForeground() {
		if let router = self.messageRouter { self.startup(withRouter: router) }
	}
	
	public func locateDevice() {
		if self.deviceLocator != nil { return }			//already locating
		
		self.deviceLocator = PeerScanner(delegate: self)
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

extension PeerSession: DeviceLocatorDelegate {
	func didLocate(device: PeerDevice) {
		self.devices[device.peerID] = device
	}
	
	func didFailToLocateDevice() {
		self.deviceLocator?.stopLocating()
	}
}
