//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import Foundation
import MultipeerConnectivity

extension MCPeerID: @unchecked Sendable { }

extension MCPeerID: Comparable {
    public static func <(lhs: MCPeerID, rhs: MCPeerID) -> Bool {
        lhs.displayName < rhs.displayName
    }
}

public extension MCPeerID {
    static let defaultsKey = "local-peerID"
    @MainActor static let localPeerID: MCPeerID = {
        if let data = UserDefaults.standard.data(forKey: defaultsKey), let id = MCPeerID.from(data: data) {
            return id
        }
        
        let peerID = MCPeerID(displayName: NearbySession.localDeviceName)
        UserDefaults.standard.set(peerID.data, forKey: defaultsKey)
        return peerID
    }()
    
    static func from(data: Data) -> MCPeerID? {
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)
    }
    
    var data: Data? {
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        } catch {
            nearbyLogger.error("Problem archiving a PeerID: \(error, privacy: .public)")
            return nil
        }
    }
}

