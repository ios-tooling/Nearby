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
        public private(set) var discoveryInfo: [String: String] = [:]
        public private(set) var provisionedInfo: [String: Sendable] = [:]

        public private(set) var state: NearbyDevice.State = .disconnected
        public private(set) var connectivityDescription: String = ""
        
        @NearbyActor init(_ device: NearbyDevice) {
            self.device = device
            let state = device.state
            
            let info = device.discoveryInfo
            Task { @MainActor in
                self.discoveryInfo = info
                self.state = state
            }
        }
        
        func setState(_ state: NearbyDevice.State, connectivityDescription: String) {
            self.state = state
            self.connectivityDescription = connectivityDescription
        }
        
        func setProvisionedInfo(_ info: [String: Sendable]) {
            self.provisionedInfo = info
        }
    }
}
