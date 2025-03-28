//
//  MCPeerID+Additions.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Suite

extension MCPeerID {
	static var deviceName: String {
		#if os(OSX)
			return ProcessInfo.processInfo.hostName
		#else
			return UIDevice.current.name
		#endif
	}
	
	static var deviceSerialNumber: String {
		#if os(OSX)
			return Gestalt.serialNumber ?? ""
		#else
			return UIDevice.current.identifierForVendor?.uuidString ?? ""
		#endif
	}
	
	static let defaultsKey = "local-peerID"

	public static func resetLocalPeerID() {
		cachedLocalPeerID = nil
		UserDefaults.standard.removeObject(forKey: defaultsKey)
		_ = localPeerID
	}
	
	static var cachedLocalPeerID: MCPeerID?
	static var localPeerID: MCPeerID {
		if let id = self.cachedLocalPeerID { return id }
		
		if let data = UserDefaults.standard.data(forKey: defaultsKey), let id = MCPeerID.from(data: data) {
			self.cachedLocalPeerID = id
			return id
		}
		
		let peerID = MCPeerID(displayName: NearbySession.instance.localDeviceName)
		UserDefaults.standard.set(peerID.data, forKey: defaultsKey)
		self.cachedLocalPeerID = peerID
		return peerID
	}
	
	var data: Data? {
		do {
			return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
		} catch {
			logg(error: error, "Problem archiving a PeerID")
			return nil
		}
	}
	
	static func from(data: Data) -> MCPeerID? {
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)
	}
}
