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
	public let invitationTimeout: TimeInterval = 30.0
	weak var rsvpCheckTimer: Timer?
	public var lastReceivedSessionState = MCSessionState.connected
	public var discoveryInfo: [String: String]?
	public var deviceInfo: [String: String]? { didSet { updateDeviceInfo(from: oldValue) } }

	public var displayName: String { didSet { sendChanges() }}
	public weak var delegate: NearbyDeviceDelegate?
	public let peerID: MCPeerID
	public let isLocalDevice: Bool
	public var uniqueID: String
	
	public var state: State = .none { didSet {
		defer { sendChanges() }
		if state == .connected {
			if deviceInfo != nil { NearbyDevice.Notifications.deviceConnectedWithInfo.post(with: self) }
			NearbyDevice.Notifications.deviceConnected.post(with: self)
		}
		if state == oldValue { return }
		delegate?.didChangeState(for: self)
		checkForRSVP(state == .invited)
		sendChanges()
	}}
	
	var idiom: String = "unknown"
	var isIPad: Bool { return idiom == "pad" }
	var isIPhone: Bool { return idiom == "phone" }
	var isMac: Bool { return idiom == "mac" }

	public required init(asLocalDevice: Bool) {
		isLocalDevice = asLocalDevice
		uniqueID = MCPeerID.deviceSerialNumber
		discoveryInfo = [
			Keys.name: MCPeerID.deviceName,
			Keys.unique: uniqueID
		]
		
		if asLocalDevice {
			#if os(macOS)
				idiom = "mac"
				discoveryInfo?[Keys.idiom] = "mac"
			#endif
			#if os(iOS)
				switch UIDevice.current.userInterfaceIdiom {
				case .phone: idiom = "phone"
				case .pad: idiom = "pad"
				case .mac: idiom = "mac"
				default: idiom = "unknown"
				}
				discoveryInfo?[Keys.idiom] = idiom
			#endif
		}
		
		peerID = MCPeerID.localPeerID
		displayName = MCPeerID.deviceName
		super.init()
	}
	
	public required init(peerID: MCPeerID, info: [String: String]) {
		isLocalDevice = false
		self.peerID = peerID
		displayName = NearbySession.instance.uniqueDisplayName(from: peerID.displayName)
		discoveryInfo = info
		uniqueID = info[Keys.unique] ?? peerID.displayName
		if let idiom = info[Keys.idiom] {
			self.idiom = idiom
		}
		super.init()
		#if os(iOS)
			NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		#endif
		startSession()
	}
	
	static func ==(lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
		return lhs.peerID == rhs.peerID
	}

	@objc func enteredBackground() {
		self.disconnectFromPeers(completion: nil)
	}
	
	func sendChanges() { Task { await MainActor.run { objectWillChange.send() } } }
	
	func updateDeviceInfo(from oldValue: [String: String]?) {
		if isLocalDevice {
			NearbySession.instance.localDeviceInfo = deviceInfo ?? [:]
			return
		}
		if oldValue == nil {
			delegate?.didReceiveFirstInfo(from: self)
			NearbyDevice.Notifications.deviceConnectedWithInfo.post(with: self)
			NearbyDevice.Notifications.deviceChangedInfo.post(with: self)
		} else if deviceInfo != oldValue {
			delegate?.didChangeInfo(from: self)
			NearbyDevice.Notifications.deviceChangedInfo.post(with: self)
		}
	}
}
