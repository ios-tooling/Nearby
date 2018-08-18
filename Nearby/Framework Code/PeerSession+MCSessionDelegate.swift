//
//  DeviceSession+MCSessionDelegate.swift
//  SpotEm
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension PeerSession {
	func device(for peerID: MCPeerID) -> PeerDevice? {
		if let device = self.devices[peerID] {
			return device
		}

		return nil
	}
}

