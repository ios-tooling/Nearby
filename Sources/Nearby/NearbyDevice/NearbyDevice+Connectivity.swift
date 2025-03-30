//
//  NearbyDevice+Connectivity.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/28/25.
//

import MultipeerConnectivity

extension NearbyDevice {
    func invite() async {
       // if await peerID > NearbyDevice.local.peerID { return }
        
        if let session {
            NearbySession.instance.scanner.scanner.invitePeer(peerID, to: session, withContext: Data(), timeout: 30.0)
        }
    }
    
    func reconnect() {
        guard !state.isConnected else { return }
        if state.isNotAvailable {
            session?.disconnect()
            NearbyLog.log(.reinvited(peerID))
            session = MCSession(peer: .localPeerID, securityIdentity: nil, encryptionPreference: .optional)
            NearbySession.instance.scanner.scanner.invitePeer(peerID, to: session!, withContext: nil, timeout: 30.0)
        } else {
            NearbyLog.log(.reconnected(peerID))
            didConnect()
        }
    }
}
