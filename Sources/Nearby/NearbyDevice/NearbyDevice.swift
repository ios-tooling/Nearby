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
	public static var autoReconnect = true
	public var session: MCSession?
	public var invitationTimeout: TimeInterval = 30.0
	public var infoReRequestDelay: TimeInterval = 2.0
	public var avatarReRequestDelay: TimeInterval = 2.0
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
	public weak var avatarRequestTimer: Timer?
	public var avatarRequestedAt: Date?
	public var infoRequestedAt: Date?

	let maxAvatarSize = 200.0
	public var avatarImage: UXImage? { didSet {
		if self.isLocalDevice, let avatarImage, (avatarImage.size.height > maxAvatarSize || avatarImage.size.width > maxAvatarSize) {
			self.avatarImage = avatarImage.resized(to: CGSize(width: maxAvatarSize, height: maxAvatarSize))
		}
		if isLocalDevice { updateDiscoveryInfo() }
	}}
	public var avatarName: String? { didSet { if isLocalDevice { updateDiscoveryInfo() } }}
	public var lastReceivedAvatarAt: Date?
	
	var reconnectionTask: Task<Void, Never>?
	var reconnectionDelay: TimeInterval = 0.5

	public var state: State = .none { didSet {
		if state == oldValue { return }
		if state < oldValue, Self.autoReconnect { attemptReconnection() }
		switch state {
		case .connected:
			didConnect()

		case .provisioned:
			NearbyDevice.Notifications.deviceProvisioned.post(with: self)

		case .disconnected:
			clearInfoRequestTimer()
			clearAvatarRequestTimer()
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
	public var deviceRawType: String? { discoveryInfo?[Keys.deviceRawType] }

	func updateDiscoveryInfo() {
		if discoveryInfo == nil {
			discoveryInfo = [
				Keys.deviceRawType: Gestalt.simulatedRawDeviceType ?? Gestalt.rawDeviceType,
				Keys.name: NearbySession.instance.localDeviceName,
				Keys.unique: uniqueID
			]
		} else {
			discoveryInfo?[Keys.name] = NearbySession.instance.localDeviceName
		}
		
		if let md5 = [avatarName, avatarImage?.pngData()].md5 { discoveryInfo?[Keys.avatarHash] = md5 }
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
		print("Received discovery info: \(info)")
		if let avatar = AvatarCache.instance.avatarInfo(forHash: info[Keys.avatarHash]) {
			avatarImage = avatar.image
			avatarName = avatar.name
		}
	}
	
	static func ==(lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
		return lhs.peerID == rhs.peerID
	}
	
	public func sendDeviceInfo() { send(message: NearbySystemMessage.DeviceInfo()) }
	public func requestInfo() { send(message: NearbySystemMessage.requestDeviceInfo) }
	public func requestAvatar() { send(message: NearbySystemMessage.requestAvatar) }

	func sendAvatar() {
		guard let message = NearbySystemMessage.Avatar(name: NearbyDevice.localDevice.avatarName, image: NearbyDevice.localDevice.avatarImage) else { return }
		
		send(message: message)
	}
	
	@objc func enteredBackground() {
		self.disconnectFromPeers(completion: nil)
	}
	
	func sendChanges() { Task { await MainActor.run { objectWillChange.send() } } }
	
	func didConnect() {
		lastConnectedAt = Date()
		NearbyDevice.Notifications.deviceConnected.post(with: self)
		if NearbySession.instance.alwaysRequestInfo {
			DispatchQueue.main.async {
				self.setupInfoRequestTimer()
			}
		}
	}
	
	func clearInfoRequestTimer() {
		infoRequestedAt = nil
		infoRequestTimer?.invalidate()
		infoRequestTimer = nil
	}
	
	func clearAvatarRequestTimer() {
		avatarRequestTimer?.invalidate()
		avatarRequestTimer = nil
	}
	
	func setupInfoRequestTimer(delay: TimeInterval? = nil) {
		if let date = infoRequestedAt, abs(date.timeIntervalSinceNow) < infoReRequestDelay { return }
		
		clearInfoRequestTimer()
		if !state.isConnected { return }

		infoRequestedAt = Date()
		DispatchQueue.main.async {
			self.infoRequestTimer = Timer.scheduledTimer(withTimeInterval: delay ?? self.infoReRequestDelay, repeats: false) { _ in
				self.requestInfo()
				self.infoRequestedAt = nil
				self.setupInfoRequestTimer()
			}
		}
	}
	
	func setupAvatarRequestTimer(delay: TimeInterval? = nil) {
		if let date = avatarRequestedAt, abs(date.timeIntervalSinceNow) < avatarReRequestDelay { return }
		clearAvatarRequestTimer()
		if !state.isConnected { return }
	
		avatarRequestedAt = Date()
		DispatchQueue.main.async {
			self.avatarRequestTimer = Timer.scheduledTimer(withTimeInterval: delay ?? self.avatarReRequestDelay, repeats: false) { _ in
				self.requestAvatar()
				self.setupAvatarRequestTimer()
			}
		}
	}
	
	func avatarReceived(via message: NearbySystemMessage.Avatar) {
		print("Received avatar image \(message.image?.size ?? .zero) and name \(message.name ?? "--")")
		clearAvatarRequestTimer()
		avatarImage = message.image
		avatarName = message.name
		AvatarCache.instance.store(message)
		lastReceivedAvatarAt = Date()
		sendChanges()
	}
	
	func updateDeviceInfo(from oldValue: [String: String]?) {
		clearInfoRequestTimer()
		
		guard !isLocalDevice else {
			NearbySession.instance.localDeviceInfo = deviceInfo ?? [:]
			return
		}
		
		if avatarImage == nil, avatarName == nil { setupAvatarRequestTimer(delay: 0) }
		self.state = .provisioned
		if oldValue == nil {
			delegate?.didReceiveFirstInfo(from: self)
		} else if deviceInfo != oldValue {
			delegate?.didChangeInfo(from: self)
			NearbyDevice.Notifications.deviceChangedInfo.post(with: self)
		}
	}
}
