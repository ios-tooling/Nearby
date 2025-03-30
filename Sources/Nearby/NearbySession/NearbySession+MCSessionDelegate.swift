//
//  NearbySession+MCSessionDelegate.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/28/25.
//

import MultipeerConnectivity

extension NearbySession: MCSessionDelegate {
    public nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NearbyLog.log(.peerStateChanged(peerID, state))
        Task { @NearbyActor in
            self[peerID]?.setSessionState(state)
        }
    }

    public nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @NearbyActor in
            NearbyMessageManager.instance.received(data: data, from: peerID)
        }
    }
    
    public nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("session received stream")
    }
    
    public nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
        print("session received resource")
    }
    
    public nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        
        print("session finished resource")
    }
    
//    public nonisolated func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
//        
//        print("session received certificate")
//    }
}
