//
//  NearbyDevice.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit

public protocol NearbyDeviceDelegate: class {
	func didReceive(message: NearbyMessage, from: NearbyDevice)
	func didReceiveFirstInfo(from: NearbyDevice)
	func didChangeInfo(from: NearbyDevice)
	func didChangeState(for: NearbyDevice)
}

open class NearbyDevice: NSObject {
	public struct Notifications {
		public static let deviceChangedState = Notification.Name("device-state-changed")
		public static let deviceConnected = Notification.Name("device-connected")
		public static let deviceConnectedWithInfo = Notification.Name("device-connected-with-info")
		public static let deviceDisconnected = Notification.Name("device-disconnected")
		public static let deviceChangedInfo = Notification.Name("device-changed-info")
	}
	
	public static let localDevice = NearbySession.deviceClass.init(asLocalDevice: true)
	
	public enum State: Int, Comparable { case none, found, invited, connecting, connected
		var description: String {
			switch self {
			case .none: return "None"
			case .found: return "Found"
			case .invited: return "Invited"
			case .connected: return "Connected"
			case .connecting: return "Connecting"
			}
		}
		
		var color: UXColor {
			switch self {
			case .none: return .gray
			case .found: return .yellow
			case .invited: return .orange
			case .connected: return .green
			case .connecting: return .blue
			}
		}
		
		var contrastingColor: UXColor {
			switch self {
			case .found, .invited, .connected: return .black
			default: return .white
			}
		}
		
		public static func < (lhs: State, rhs: State) -> Bool { return lhs.rawValue < rhs.rawValue }

	}
	
	public var lastReceivedSessionState = MCSessionState.connected
	open var discoveryInfo: [String: String]?
	public var deviceInfo: [String: String]? { didSet {
		if oldValue == nil {
			self.delegate?.didReceiveFirstInfo(from: self)
			NearbyDevice.Notifications.deviceConnectedWithInfo.post(with: self)
			NearbyDevice.Notifications.deviceChangedInfo.post(with: self)
		} else if self.deviceInfo != oldValue {
			self.delegate?.didChangeInfo(from: self)
			NearbyDevice.Notifications.deviceChangedInfo.post(with: self)
		}
	}}
	public var displayName: String
	public weak var delegate: NearbyDeviceDelegate?
	public let peerID: MCPeerID
	public let isLocalDevice: Bool
	public var uniqueID: String
	
	open var state: State = .none { didSet {
		if self.state == .connected {
			if self.deviceInfo != nil { NearbyDevice.Notifications.deviceConnectedWithInfo.post(with: self) }
			NearbyDevice.Notifications.deviceConnected.post(with: self)
		}
		if self.state == oldValue { return }
		//Logger.instance.log("\(self.displayName), \(oldValue.description) -> \(self.state.description)")
		self.delegate?.didChangeState(for: self)
		self.checkForRSVP(self.state == .invited)
	}}
	
	#if os(iOS)
		let idiom: UIUserInterfaceIdiom
		var isIPad: Bool { return self.idiom == .pad }
		var isIPhone: Bool { return self.idiom == .phone }
	#endif
	
	public var session: MCSession?
	public let invitationTimeout: TimeInterval = 30.0
	weak var rsvpCheckTimer: Timer?
	
	public var attributedDescription: NSAttributedString {
		if self.isLocalDevice { return NSAttributedString(string: "Local Device", attributes: [.foregroundColor: UXColor.black]) }
		return NSAttributedString(string: self.displayName, attributes: [.foregroundColor: self.state.color, .font: UXFont.boldSystemFont(ofSize: 14)])
	}
	
	open override var description: String {
		var string = self.displayName
		#if os(iOS)
			if self.isIPad { string += ", iPad" }
			if self.isIPhone { string += ", iPhone" }
		#endif
		return string
	}

	public required init(asLocalDevice: Bool) {
		self.isLocalDevice = asLocalDevice
		self.uniqueID = MCPeerID.deviceSerialNumber
		self.discoveryInfo = [
			Keys.name: MCPeerID.deviceName,
			Keys.unique: self.uniqueID
		]
		
		#if os(iOS)
			self.idiom = UIDevice.current.userInterfaceIdiom
			self.discoveryInfo?[Keys.idiom] = "\(UIDevice.current.userInterfaceIdiom.rawValue)"
		#endif
		
		self.peerID = MCPeerID.localPeerID
		self.displayName = MCPeerID.deviceName
		super.init()
	}
	
	public required init(peerID: MCPeerID, info: [String: String]) {
		self.isLocalDevice = false
		self.peerID = peerID
		self.displayName = NearbySession.instance.uniqueDisplayName(from: self.peerID.displayName)
		self.discoveryInfo = info
		self.uniqueID = info[Keys.unique] ?? peerID.displayName
		#if os(iOS)
			if let string = info[Keys.idiom], let int = Int(string), let idiom = UIUserInterfaceIdiom(rawValue: int) {
				self.idiom = idiom
			} else {
				self.idiom = .phone
			}
		#endif
		super.init()
		#if os(iOS)
			NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		#endif
		self.startSession()
	}
	
	@objc func enteredBackground() {
		self.disconnectFromPeers(completion: nil)
	}
	
	func disconnectFromPeers(completion: (() -> Void)?) {
		Logger.instance.log("Disconnecting from peers")
		#if os(iOS)
			let taskID = NearbySession.instance.application.beginBackgroundTask {
				completion?()
			}
			self.send(message: NearbySystemMessage.disconnect, completion: {
				self.stopSession()
				DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1) {
					completion?()
					NearbySession.instance.application.endBackgroundTask(taskID)
				}
			})
		#else
			self.send(message: NearbySystemMessage.disconnect, completion: { completion?() })
		#endif
	}

	@discardableResult
	func invite(with browser: MCNearbyServiceBrowser) -> Bool {
		guard let info = NearbyDevice.localDevice.discoveryInfo, let data = try? JSONEncoder().encode(info) else { return false }
		self.startSession()
		guard let session = self.session else { return false }
		self.state = .invited
		browser.invitePeer(self.peerID, to: session, withContext: data, timeout: self.invitationTimeout)
		return true
	}
	
	func receivedInvitation(from: MCPeerID, withContext context: Data?, handler: @escaping (Bool, MCSession?) -> Void) {
		self.state = .connected
		self.startSession()
		handler(true, self.session)
	}
	
	func session(didChange state: MCSessionState) {
		self.lastReceivedSessionState = state
		var newState = self.state
		let oldState = self.state
		
		switch state {
		case .connected:
			newState = .connected
		case .connecting:
			newState = .connecting
			self.startSession()
		case .notConnected:
			newState = .found
			self.disconnect()
			NearbySession.instance.deviceLocator?.reinvite(device: self)

		@unknown default: break
		}
		
		if newState == self.state {
			return
		}
		self.state = newState
		defer { Notifications.deviceChangedState.post(with: self) }
		
		if self.state == .connected {
			NearbyDevice.Notifications.deviceConnected.post(with: self)
			if self.deviceInfo != nil { NearbyDevice.Notifications.deviceConnectedWithInfo.post(with: self) }
			if NearbySession.instance.alwaysRequestInfo {
				self.send(message: NearbySystemMessage.DeviceInfo())
			}
			return
		} else if self.state == .connecting {
			self.startSession()
		}
		
		if self.state != .connected, oldState == .connected {
			Notifications.deviceDisconnected.post(with: self)
		}
	}
	
	open func disconnect() {
		self.state = .none
		Notifications.deviceDisconnected.post(with: self)
		self.stopSession()
	}
	
	func stopSession() {
		Logger.instance.log("Stopping: \(self.session == nil ? "nothing" : "session")")
		self.session?.disconnect()
		self.session = nil
	}
	
	func startSession() {
		if self.session == nil {
			self.session = MCSession(peer: NearbyDevice.localDevice.peerID, securityIdentity: nil, encryptionPreference: NearbySession.instance.useEncryption ? .required : .none)
			self.session?.delegate = self
		}
	}
	
	open func send<MessageType: NearbyMessage>(message: MessageType, completion: (() -> Void)? = nil) {
		if self.isLocalDevice || self.session == nil {
			completion?()
			return
		}

		Logger.instance.log("Sending \(message.command) as a \(type(of: message)) to \(self.displayName)")
		let payload = NearbyMessagePayload(message: message)
		self.send(payload: payload)
		completion?()
	}
	
	func send(payload: NearbyMessagePayload?) {
		guard let data = payload?.payloadData else { return }
		do {
			try self.session?.send(data, toPeers: [self.peerID], with: .reliable)
		} catch {
			Logger.instance.log("Error \(error) when sending to \(self.displayName)")
		}
	}
	
	func session(didReceive data: Data) {
		guard let payload = NearbyMessagePayload(data: data) else {
			Logger.instance.log("Failed to decode message from \(data)")
			return
		}
		
		if let message = InternalRouter.instance.route(payload, from: self) {
			self.delegate?.didReceive(message: message, from: self)
		} else if let message = NearbySession.instance.messageRouter?.route(payload, from: self) {
			self.delegate?.didReceive(message: message, from: self)
		}
	}
	
	func session(didReceive stream: InputStream, withName streamName: String) {
		
	}
	
	func session(didStartReceivingResourceWithName resourceName: String, with progress: Progress) {
		
	}
	
	func session(didFinishReceivingResourceWithName resourceName: String, at localURL: URL?, withError error: Error?) {
		
	}
	
	static func ==(lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
		return lhs.peerID == rhs.peerID
	}
}

extension NearbyDevice {
	struct Keys {
		static let name = "name"
		static let idiom = "idiom"
		static let unique = "unique"
	}
}

extension MCSessionState: CustomStringConvertible {
	public var description: String {
		switch self {
		case .connected: return "*conected*"
		case .notConnected: return "*notConnected*"
		case .connecting: return "*connecting*"
		@unknown default: return "*unknown*"
		}
	}
}
