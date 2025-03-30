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
        init() {
            super.init(peerID: .localPeerID, info: nil)
        }
        
        public func setDiscoveryInfo(_ info: [String: String]) {
            self.discoveryInfo = info
            Task {
                await NearbySession.instance.scanner.updateDiscoveryInfo(discoveryInfo)
            }
        }
        
        public func setProvisionedInfo(_ info: [String: Sendable]) {
            provisionedInfo = info
            let provisioned = NearbySession.instance.provisionedDevices
            Task {
                for device in provisioned {
                    await device.send(message: ProvisionMessage())
                }
            }
        }
    }
}
