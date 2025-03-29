//
//  NearbyScanner+Advertising.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import Foundation
import MultipeerConnectivity

extension NearbyScanner: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from \(peerID)")
        
        invitationHandler(true, NearbySession.session)
        
//        Task { @NearbyActor in
//            invitationHandler(true, NearbySession.instance.session)
//        }
    }
    
    nonisolated public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start for peer: \(error)")
        Task {
            await self.setRecentError(ScannerError.advertising(error))
            await self.stopAdvertising()
        }
    }
}
