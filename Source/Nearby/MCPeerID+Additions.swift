//
//  MCPeerID+Additions.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension MCPeerID {
	static var cachedLocalPeerID: MCPeerID?
	static var localPeerID: MCPeerID {
		if let id = self.cachedLocalPeerID { return id }
		
		let key = "local-peerID"
		if let data = UserDefaults.standard.data(forKey: key), let id = MCPeerID.from(data: data) {
			self.cachedLocalPeerID = id
			return id
		}
		
		let peerID = MCPeerID(displayName: UIDevice.current.name)
		UserDefaults.standard.set(peerID.data, forKey: key)
		self.cachedLocalPeerID = peerID
		return peerID
	}
	
	var data: Data {
		return NSKeyedArchiver.archivedData(withRootObject: self)
	}
	
	static func from(data: Data) -> MCPeerID? {
		return NSKeyedUnarchiver.unarchiveObject(with: data) as? MCPeerID
	}
}
