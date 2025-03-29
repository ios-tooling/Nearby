//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import MultipeerConnectivity
import Suite

extension NearbyDevice {
    public enum State: String, Sendable { case connected, paired, disconnected }
}

@NearbyActor public class NearbyDevice: Hashable, Comparable {
    public nonisolated let peerID: MCPeerID
    public var info: [String: Sendable] = [:]
    public var ui: UI!
    public static var local: LocalDevice!
    public var isDisconnected = false
    
    public var state: State {
        if isDisconnected { return .disconnected }
        return .connected
    }
    
    @NearbyActor init(peerID: MCPeerID) {
        self.peerID = peerID
        self.ui = UI(self)
    }
    
    func didDisconnect() {
        print("Did disconnect")
        isDisconnected = true
        Task { await ui.setState(state) }
    }
    
    func didConnect() {
        print("Did connect")
        isDisconnected = false
        Task { await ui.setState(state) }
    }
    
    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(peerID)
    }
    
    public nonisolated static func == (lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
        lhs.peerID == rhs.peerID
    }
    
    public nonisolated static func < (lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
        lhs.peerID < rhs.peerID
    }
}
