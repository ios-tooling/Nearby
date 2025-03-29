//
//  NearbyScanner+Browsing.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import Foundation
import MultipeerConnectivity

extension NearbyScanner: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Task { @NearbyActor in
            let device = await NearbySession.instance.buildDevice(for: peerID, info: info)
            print("Found \(peerID.displayName), inviting…")
            await device.invite()
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Browser disconnected \(peerID.displayName)")
        Task {
            await NearbySession.instance.didLose(peerID: peerID)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task {
            await self.setRecentError(ScannerError.browsing(error))
            await self.setIsAdvertising(false)
        }
    }
}
