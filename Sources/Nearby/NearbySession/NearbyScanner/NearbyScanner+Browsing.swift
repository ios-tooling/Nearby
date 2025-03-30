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
        NearbyLog.log(.browserFoundPeer(peerID, info))
        Task { @NearbyActor in
            let device = await NearbySession.instance.buildDevice(for: peerID, info: info)
            device.appearedInBrowser()
            if device.state.isConnected { return }
            NearbyLog.log(.foundInvitablePeer(peerID))
            await device.invite()
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NearbyLog.log(.browserLostPeer(peerID))
        Task {
            await NearbySession.instance.didLose(peerID: peerID)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task {
            NearbyLog.log(.browserFailedToStart(error))
            await self.setRecentError(ScannerError.browsing(error))
            await self.setIsAdvertising(false)
        }
    }
}
