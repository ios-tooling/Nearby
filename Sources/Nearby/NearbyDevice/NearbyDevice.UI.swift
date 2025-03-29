//
//  NearbyDevice.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/27/25.
//

import Suite
import MultipeerConnectivity

extension NearbyDevice {
    @MainActor @Observable public class UI: Identifiable {
        nonisolated let device: NearbyDevice
        public nonisolated var id: MCPeerID { device.peerID }
        public private(set) var info: [String: Sendable] = [:]
        
        public private(set) var state: NearbyDevice.State = .disconnected
        
        @NearbyActor init(_ device: NearbyDevice) {
            self.device = device
            let state = device.state
            
            let info = device.info
            Task { @MainActor in
                self.info = info
                self.state = state
            }
        }
        
        func setState(_ state: NearbyDevice.State) {
            self.state = state
        }
    }
}
