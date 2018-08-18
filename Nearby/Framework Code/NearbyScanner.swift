//
//  DeviceLocator.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol DeviceLocatorDelegate: class {
	func didLocate(device: NearbyDevice)
	func didFailToLocateDevice()
}

class NearbyScanner: NSObject {
	var advertiser: MCNearbyServiceAdvertiser!
	var browser: MCNearbyServiceBrowser!
	weak var delegate: DeviceLocatorDelegate!
	
	var isLocating = false
	var isBrowsing = false { didSet { self.updateState() }}
	var isAdvertising = false { didSet { self.updateState() }}
	
	var peerID: MCPeerID { return NearbySession.instance.peerID }
	
	init(delegate: DeviceLocatorDelegate) {
		super.init()
		
		self.delegate = delegate
		self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: NearbyDevice.localDevice.discoveryInfo, serviceType: NearbySession.instance.serviceType)
		self.advertiser.delegate = self
		
		self.browser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: NearbySession.instance.serviceType)
		self.browser.delegate = self
	}
}

extension NearbyScanner {
	func stopLocating() {
		self.browser?.stopBrowsingForPeers()
		self.advertiser?.stopAdvertisingPeer()
		self.isLocating = false
		self.isBrowsing = false
		self.isAdvertising = false
	}
	
	func startLocating() {
		self.isLocating = true
		self.isBrowsing = true
		self.isAdvertising = true
		
		self.browser.startBrowsingForPeers()
		self.advertiser.startAdvertisingPeer()
	}
	
	func updateState() {
		if self.isLocating, !self.isAdvertising, !self.isBrowsing {
			self.isLocating = false
		}
	}
	
	func reinvite(device: NearbyDevice) {
		if device.state < .invited {
			device.invite(with: self.browser)
		}
	}
}

extension NearbyScanner: MCNearbyServiceAdvertiserDelegate {
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		if let device = NearbySession.instance.device(for: peerID) {
			device.receivedInvitation(withContext: context, handler: invitationHandler)
		} else if let data = context, let info = try? JSONDecoder().decode([String: String].self, from: data) {
			let device = NearbySession.deviceClass.init(peerID: peerID, info: info)
			self.delegate.didLocate(device: device)
		} else {
			invitationHandler(false, nil)
		}
	}
	
	public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		Logger.instance.log("Error when starting advertising: \(error)")
		self.isAdvertising = false
	}
}

extension NearbyScanner: MCNearbyServiceBrowserDelegate {
	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		guard let info = info else {
			Logger.instance.log("No discovery info found for \(peerID.displayName)")
			return
		}
		Logger.instance.log("Found peer: \(peerID.displayName)")
		let device = NearbySession.instance.device(for: peerID) ?? NearbySession.deviceClass.init(peerID: peerID, info: info)
		self.delegate.didLocate(device: device)
		if device.state != .connected && device.state != .invited {
			device.state = .found
			device.stopSession()
		}
		device.invite(with: self.browser)
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		Logger.instance.log("Lost peer: \(peerID.displayName)")
		if let device = NearbySession.instance.device(for: peerID) {
			device.disconnect()
		}
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
		Logger.instance.log("Error when starting browsing: \(error)")
		self.isBrowsing = false
	}
}
