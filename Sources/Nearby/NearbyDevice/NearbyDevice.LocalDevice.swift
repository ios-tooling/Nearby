//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/27/25.
//

import Foundation
import MultipeerConnectivity

extension NearbyDevice {
    
    @NearbyActor public class LocalDevice: NearbyDevice {
        public private(set) var discoveryInfo: [String: String] = [:]

        init() async {
            super.init(peerID: await .localPeerID)
        }
        
        public func updateDiscoveryInfo(_ info: [String: String]) {
            self.discoveryInfo = info
            Task {
                Task {
                    await NearbySession.instance.scanner.updateDiscoveryInfo(discoveryInfo)
                }
            }
        }

    }
}
