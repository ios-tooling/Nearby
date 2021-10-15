//
//  MCPeerID+Additions.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Studio

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
	
	static var cachedLocalPeerID: MCPeerID?
	static var localPeerID: MCPeerID {
		if let id = self.cachedLocalPeerID { return id }
		
		let key = "local-peerID"
		if let data = UserDefaults.standard.data(forKey: key), let id = MCPeerID.from(data: data) {
			self.cachedLocalPeerID = id
			return id
		}
		
		let peerID = MCPeerID(displayName: Self.deviceName)
		UserDefaults.standard.set(peerID.data, forKey: key)
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
