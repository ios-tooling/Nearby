//
//  Device.swift
//  SpotEm
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity


public protocol PeerDeviceDelegate: class {
	func didReceive(message: PeerMessage, from: PeerDevice)
	func didChangeState(for: PeerDevice)
}

public class PeerDevice: NSObject {
	public struct Notifications {
		public static let deviceStateChanged = Notification.Name("device-state-changed")
		public static let deviceConnected = Notification.Name("device-connected")
		public static let deviceDisconnected = Notification.Name("device-disconnected")
	}
	
	public static let localDevice = PeerDevice(asLocalDevice: true)
	
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
		
		var color: UIColor {
			switch self {
			case .none: return .gray
			case .found: return .yellow
			case .invited: return .orange
			case .connected: return .green
			case .connecting: return .blue
			}
		}
		
		public static func < (lhs: State, rhs: State) -> Bool { return lhs.rawValue < rhs.rawValue }

	}
	
	public var displayName: String
	public weak var delegate: PeerDeviceDelegate?
	public let peerID: MCPeerID
	public var discoveryInfo: [String: String]?
	public var state: State = .none { didSet {
		if self.state == oldValue { return }
		Logger.instance.log("\(self.displayName), \(oldValue.description) -> \(self.state.description)")
		self.delegate?.didChangeState(for: self)
		self.checkForRSVP(self.state == .invited)
	}}
	let idiom: UIUserInterfaceIdiom
	var isIPad: Bool { return self.idiom == .pad }
	var isIPhone: Bool { return self.idiom == .phone }
	public var session: MCSession?
	public let invitationTimeout: TimeInterval = 30.0
	public let isLocalDevice: Bool
	public var uniqueID: String!
	weak var rsvpCheckTimer: Timer?
	
	public var attributedDescription: NSAttributedString {
		if self.isLocalDevice { return NSAttributedString(string: "Local Device", attributes: [.foregroundColor: UIColor.black]) }
		return NSAttributedString(string: self.displayName, attributes: [.foregroundColor: self.state.color, .font: UIFont.boldSystemFont(ofSize: 14)])
	}
	
	public override var description: String {
		var string = self.displayName
		if self.isIPad { string += ", iPad" }
		if self.isIPhone { string += ", iPhone" }
		return string
	}

	private init(asLocalDevice: Bool) {
		self.isLocalDevice = asLocalDevice
		self.uniqueID = UIDevice.current.identifierForVendor?.uuidString ?? ""
		self.discoveryInfo = [Keys.name: UIDevice.current.name, Keys.unique: self.uniqueID, Keys.idiom: "\(UIDevice.current.userInterfaceIdiom.rawValue)"]
		self.peerID = MCPeerID.localPeerID
		self.displayName = UIDevice.current.name
		self.idiom = UIDevice.current.userInterfaceIdiom
		super.init()
	}
	
	init(peerID: MCPeerID, info: [String: String]) {
		self.isLocalDevice = false
		self.peerID = peerID
		self.displayName = PeerSession.instance.uniqueDisplayName(from: self.peerID.displayName)
		self.discoveryInfo = info
		self.uniqueID = info[Keys.unique]
		if let string = info[Keys.idiom], let int = Int(string), let idiom = UIUserInterfaceIdiom(rawValue: int) {
			self.idiom = idiom
		} else {
			self.idiom = .phone
		}
		super.init()
		self.startSession()
		NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: .UIApplicationDidEnterBackground, object: nil)
	}
	
	@objc func enteredBackground() {
		self.disconnectFromPeers(completion: nil)
	}
	
	func disconnectFromPeers(completion: (() -> Void)?) {
		print("Disconnecting from peers")
		let taskID = PeerSession.instance.application.beginBackgroundTask {
			completion?()
		}
		self.send(message: PeerSystemMessage.disconnect, completion: {
			self.stopSession()
			DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1) {
				completion?()
				PeerSession.instance.application.endBackgroundTask(taskID)
			}
		})
	}

	func invite(with browser: MCNearbyServiceBrowser) {
		guard let info = PeerDevice.localDevice.discoveryInfo, let data = try? JSONEncoder().encode(info) else { return }
		self.state = .invited
		self.startSession()
		browser.invitePeer(self.peerID, to: self.session!, withContext: data, timeout: self.invitationTimeout)
	}
	
	func receivedInvitation(withContext context: Data?, handler: @escaping (Bool, MCSession?) -> Void) {
		self.state = .connected
		self.startSession()
		handler(true, self.session)
	}
	
	func session(didChange state: MCSessionState) {
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
			PeerSession.instance.deviceLocator?.reinvite(device: self)
		}
		
		if newState == self.state { return }				// no change
		self.state = newState
		
		if self.state == .connected {
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notifications.deviceStateChanged, object: self)
				NotificationCenter.default.post(name: PeerDevice.Notifications.deviceConnected, object: self)
			}
			return
		} else if self.state == .connecting {
			self.startSession()
		}
		
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.deviceStateChanged, object: self)}
		if self.state != .connected, oldState == .connected {
			DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.deviceDisconnected, object: self)}
		}
	}
	
	public func disconnect() {
		self.state = .none
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.deviceDisconnected, object: self)}
		self.stopSession()
	}
	
	func stopSession() {
		Logger.instance.log("Stopping: \(self.session == nil ? "nothing" : "session")")
		self.session?.disconnect()
		self.session = nil
	}
	
	func startSession() {
		if self.session == nil {
			self.session = MCSession(peer: PeerDevice.localDevice.peerID, securityIdentity: nil, encryptionPreference: .required)
			self.session?.delegate = self
		}
	}
	
	public func send<MessageType: PeerMessage>(message: MessageType, completion: (() -> Void)? = nil) {
		if self.isLocalDevice || self.session == nil {
			completion?()
			return
		}

		Logger.instance.log("Sending \(message.command) to \(self.displayName)")
		let payload = PeerMessagePayload(message: message)
		self.send(payload: payload)
		completion?()
	}
	
	func send(payload: PeerMessagePayload?) {
		guard let data = payload?.payloadData else { return }
		do {
			try self.session?.send(data, toPeers: [self.peerID], with: .reliable)
		} catch {
			Logger.instance.log("Error \(error) when sending to \(self.displayName)")
		}
	}
	
	func session(didReceive data: Data) {
		guard let payload = PeerMessagePayload(data: data) else {
			Logger.instance.log("Failed to decode message from \(data)")
			return
		}
		
		if let message = InternalRouter.instance.route(payload, from: self) {
			self.delegate?.didReceive(message: message, from: self)
		} else if let message = PeerSession.instance.messageRouter?.route(payload, from: self) {
			self.delegate?.didReceive(message: message, from: self)
		}
	}
	
	func session(didReceive stream: InputStream, withName streamName: String) {
		
	}
	
	func session(didStartReceivingResourceWithName resourceName: String, with progress: Progress) {
		
	}
	
	func session(didFinishReceivingResourceWithName resourceName: String, at localURL: URL?, withError error: Error?) {
		
	}
	
	static func ==(lhs: PeerDevice, rhs: PeerDevice) -> Bool {
		return lhs.peerID == rhs.peerID
	}
}

extension PeerDevice {
	struct Keys {
		static let name = "name"
		static let idiom = "idiom"
		static let unique = "unique"
	}
}
