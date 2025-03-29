//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/28/25.
//

import MultipeerConnectivity
import Suite

extension NearbySession {
    public func buildDevice(for id: MCPeerID, info: [String : String]?) async -> NearbyDevice {
        if let existing = devices.first(where: { $0.peerID == id }) {
            existing.didConnect()
            return existing
        }
        
        let new = NearbyDevice(peerID: id)
        new.info = info ?? [:]
        devices.insert(new)
        return new
    }
    
    subscript (peerID: MCPeerID) -> NearbyDevice? {
        get {
            devices.first { $0.peerID == peerID }
        }
    }
    
    func didLose(peerID: MCPeerID) {
        self[peerID]?.didDisconnect()
    }
}
