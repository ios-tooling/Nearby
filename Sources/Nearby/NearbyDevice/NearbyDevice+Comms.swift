//
//  NearbyDevice+Comms.swift
//  Internal
//
//  Created by Ben Gottlieb on 6/13/23.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit
import Studio

extension NearbyDevice {
	func session(didReceive stream: InputStream, withName streamName: String) {
		
	}
	
	func session(didStartReceivingResourceWithName resourceName: String, with progress: Progress) {
		
	}
	
	func session(didFinishReceivingResourceWithName resourceName: String, at localURL: URL?, withError error: Error?) {
	}
	
	func connect() {
		if state != .connecting {
			NearbySession.instance.deviceLocator?.reinvite(device: self)
		}
	}
	
	func disconnectFromPeers() async {
		await withCheckedContinuation { continuation in
			disconnectFromPeers { continuation.resume() }
		}
	}
	
	func disconnectFromPeers(completion: (() -> Void)? = nil) {
		NearbyLogger.instance.log("Disconnecting from peers", onlyWhenDebugging: true)
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
		if !self.state.isConnected { self.state = .connected }
		self.startSession()
		lastSeenAt = Date()
		handler(true, self.session)
	}
	
	func session(didChange state: MCSessionState) {
		self.lastReceivedSessionState = state
		var newState = self.state
		let oldState = self.state
		
		switch state {
		case .connected:
			lastSeenAt = Date()
			newState = .connected
		case .connecting:
			lastSeenAt = Date()
			newState = .connecting
			self.startSession()
		case .notConnected:
			newState = .found
			self.disconnect()
			Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in NearbySession.instance.deviceLocator?.reinvite(device: self) }

		@unknown default: break
		}
		
		if newState == self.state {
			return
		}
		self.state = newState
		defer { Notifications.deviceChangedState.post(with: self) }
		
		if self.state.isConnected {
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
	
	public func send(dictionary: [String: String], completion: (() -> Void)? = nil) {
		if isLocalDevice || session == nil {
			completion?()
			return
		}

		NearbyLogger.instance.log("Sending dictionary \(dictionary) to \(displayName)")
		let payload = NearbyMessagePayload(message: NearbySystemMessage.DictionaryMessage(dictionary: dictionary))
		send(payload: payload)
		completion?()
	}
	
	public func send<MessageType: NearbyMessage>(message: MessageType, completion: (() -> Void)? = nil) {
		if isLocalDevice || session == nil {
			completion?()
			return
		}

		NearbyLogger.instance.log("Sending \(message.command) as a \(type(of: message)) to \(displayName)", onlyWhenDebugging: true)
		let payload = NearbyMessagePayload(message: message)
		send(payload: payload)
		completion?()
	}
	
	func send(payload: NearbyMessagePayload?) {
		guard let payload else { return }
		NearbyLogger.instance.log("Sending \(payload.command) as a \(type(of: payload)) to \(displayName)", onlyWhenDebugging: true)
		do {
			try session?.send(payload.payloadData, toPeers: [peerID], with: .reliable)
		} catch {
			NearbyLogger.instance.log("Error \(error) when sending to \(displayName)")
		}
	}
	 
	public func send(file url: URL, named name: String, completion: ((Error?) -> Void)? = nil) {
		  session?.sendResource(at: url, withName: name, toPeer: peerID, withCompletionHandler:  completion)
	 }
	
	func session(didReceive data: Data) {
		guard let payload = NearbyMessagePayload(data: data) else {
			NearbyLogger.instance.log("Failed to decode message from \(data)")
			return
		}
		
		if let message = InternalRouter.instance.route(payload, from: self) {
			delegate?.didReceive(message: message, from: self)
		} else if let message = NearbySession.instance.messageRouter?.route(payload, from: self) {
			delegate?.didReceive(message: message, from: self)
		}
	}
	
	public func disconnect() {
		self.state = .none
		Notifications.deviceDisconnected.post(with: self)
		self.stopSession()
	}
	
	func stopSession() {
		NearbyLogger.instance.log("Stopping: \(self.session == nil ? "nothing" : "session")")
		self.session?.disconnect()
		self.session = nil
	}
	
	func startSession() {
		if self.session == nil {
			self.session = MCSession(peer: NearbyDevice.localDevice.peerID, securityIdentity: nil, encryptionPreference: NearbySession.instance.useEncryption ? .required : .none)
			self.session?.delegate = self
		}
	}
}
