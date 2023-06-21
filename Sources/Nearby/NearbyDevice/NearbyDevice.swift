//
//  NearbyDevice.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit
import Studio
import SwiftUI

final public class NearbyDevice: NSObject, Comparable {
	public var session: MCSession?
	public var invitationTimeout: TimeInterval = 30.0
	public var infoReRequestDelay: TimeInterval = 5.0
	weak var rsvpCheckTimer: Timer?
	public var lastReceivedSessionState = MCSessionState.connected
	public var discoveryInfo: [String: String]?
	public var deviceInfo: [String: String]? { didSet { updateDeviceInfo(from: oldValue) } }

	public var displayName = "" { didSet { sendChanges() }}
	public weak var delegate: NearbyDeviceDelegate?
	public let peerID: MCPeerID
	public let isLocalDevice: Bool
	public var uniqueID: String
	public var lastSeenAt = Date()
	public var lastConnectedAt: Date?
	public weak var infoRequestTimer: Timer?
	
	public var state: State = .none { didSet {
		if state == oldValue { return }
		
		switch state {
		case .connected:
			didConnect()

		case .provisioned:
			NearbyDevice.Notifications.deviceProvisioned.post(with: self)

		case .disconnected:
			clearInfoRequestTimer()
			NearbyDevice.Notifications.deviceDisconnected.post(with: self)

		default: break
		}
		
		delegate?.didChangeState(for: self)
		checkForRSVP(state == .invited)
		sendChanges()
	}}
	
	public var idiom: String = "unknown"
	public var isIPad: Bool { return idiom == "pad" }
	public var isIPhone: Bool { return idiom == "phone" }
	public var isMac: Bool { return idiom == "mac" }
	public var isSimulator = false

	func updateDiscoveryInfo() {
		if discoveryInfo == nil {
			discoveryInfo = [
				Keys.device: Gestalt.rawDeviceType,
				Keys.name: NearbySession.instance.localDeviceName,
				Keys.unique: uniqueID
			]
		} else {
			discoveryInfo?[Keys.name] = NearbySession.instance.localDeviceName
		}
		displayName = NearbySession.instance.localDeviceName
		if isLocalDevice {
			discoveryInfo?[Keys.idiom] = idiomString
		}
		#if targetEnvironment(simulator)
			discoveryInfo?[Keys.simulator] = "1"
		#endif
	}

	public required init(asLocalDevice: Bool) {
		isLocalDevice = asLocalDevice
		uniqueID = MCPeerID.deviceSerialNumber
		
		peerID = MCPeerID.localPeerID
		super.init()
		updateDiscoveryInfo()
	}
	
	var idiomString: String {
		#if os(macOS)
			return "mac"
		#endif
		#if os(iOS)
			switch UIDevice.current.userInterfaceIdiom {
			case .phone: return "phone"
			case .pad: return "pad"
			case .mac: return "mac"
			default: return "unknown"
			}
		#endif
	}
	
	public required init(peerID: MCPeerID, info: [String: String]) {
		isLocalDevice = false
		self.peerID = peerID
		displayName = NearbySession.instance.uniqueDisplayName(from: peerID.displayName)
		discoveryInfo = info
		uniqueID = info[Keys.unique] ?? peerID.displayName
		if let idiom = info[Keys.idiom] { self.idiom = idiom }
		if info[Keys.simulator] != nil { self.isSimulator = true }
		super.init()
		#if os(iOS)
			NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		#endif
		startSession()
	}
	
	static func ==(lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
		return lhs.peerID == rhs.peerID
	}
	
	public func sendInfo() { send(message: NearbySystemMessage.DeviceInfo()) }
	public func requestInfo() { send(message: NearbySystemMessage.requestDeviceInfo) }

	@objc func enteredBackground() {
		self.disconnectFromPeers(completion: nil)
	}
	
	func sendChanges() { Task { await MainActor.run { objectWillChange.send() } } }
	
	func didConnect() {
		lastConnectedAt = Date()
		NearbyDevice.Notifications.deviceConnected.post(with: self)
		if NearbySession.instance.alwaysRequestInfo { setupInfoRequestTimer() }
	}
	
	func clearInfoRequestTimer() {
		infoRequestTimer?.invalidate()
		infoRequestTimer = nil
	}
	
	func setupInfoRequestTimer() {
		clearInfoRequestTimer()
		if state != .connected { return }
		
		infoRequestTimer = Timer.scheduledTimer(withTimeInterval: infoReRequestDelay, repeats: false) { _ in
			self.requestInfo()
			self.setupInfoRequestTimer()
		}
	}
	
	func updateDeviceInfo(from oldValue: [String: String]?) {
		guard !isLocalDevice else {
			NearbySession.instance.localDeviceInfo = deviceInfo ?? [:]
			return
		}
		
		self.state = .provisioned
		if oldValue == nil {
			delegate?.didReceiveFirstInfo(from: self)
		} else if deviceInfo != oldValue {
			delegate?.didChangeInfo(from: self)
			NearbyDevice.Notifications.deviceChangedInfo.post(with: self)
		}
	}
}
