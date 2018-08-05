//
//  Device+MCSessionDelegate.swift
//  SpotEm
//
//  Created by Ben Gottlieb on 6/1/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension PeerDevice: MCSessionDelegate {
	public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		self.session(didChange: state)
	}
	
	public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		self.session(didReceive: data)
	}
	
	public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		self.session(didReceive: stream, withName: streamName)
	}
	
	public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		self.session(didStartReceivingResourceWithName: resourceName, with: progress)
	}
	
	public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		self.session(didFinishReceivingResourceWithName: resourceName, at: localURL, withError: error)
	}
	
	public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
		certificateHandler(true)
	}
	
}



