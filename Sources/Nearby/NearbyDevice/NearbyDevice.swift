//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import MultipeerConnectivity
import Suite

@NearbyActor public class NearbyDevice: NSObject, Comparable {
    public nonisolated let peerID: MCPeerID
    public var discoveryInfo: [String: String] = [:]
    public internal(set) var provisionedInfo: [String: Sendable]?
    public var ui: UI!
    public static let local: LocalDevice = .init()
    public var visibleInBrowser = false
    
    public var lastConnectedAt: Date?
    public var disconnectedAt: Date?
    
    var session: MCSession?
    var sessionState: MCSessionState = .notConnected
    var isLocalDevice: Bool

    public var state: State {
        switch sessionState {
        case .connected:
            if let disconnectedAt { return .disconnected }
            return provisionedInfo == nil ? .connected : .provisioned
        case .connecting: return .connecting
        case .notConnected:
            return visibleInBrowser ? .offline : .unknown
        default: return .unknown
        }
        return .unknown
    }
    
    
    var connectivityDescription: String {
        var base = state.description + " (\(sessionState.description))"
        if let lastConnectedAt { base += ", last connected at \(lastConnectedAt.formatted(date: .omitted, time: .shortened))" }
        if let disconnectedAt { base += ", disconnected at \(disconnectedAt.formatted(date: .omitted, time: .shortened))" }

        return base
    }
    
    @NearbyActor init(peerID: MCPeerID, info: [String: String]?) {
        let isLocal = peerID == .localPeerID
        self.peerID = peerID
        self.discoveryInfo = info ?? [:]
        if !isLocal { session = MCSession(peer: .localPeerID, securityIdentity: nil, encryptionPreference: .optional) }
        self.isLocalDevice = isLocal
        super.init()
        
        session?.delegate = self
        
        NearbySession.setSession(session, for: peerID)
        self.ui = UI(self)
    }
    
    func didDisconnect() {
        disconnectedAt = .now
        updateUI()
    }
    
    func didConnect() {
        disconnectedAt = nil
        updateUI()
    }
    
    func updateProvisionedInfo(_ info: [String: Sendable]) {
        provisionedInfo = info
        Task {
            await ui.setState(state, connectivityDescription: connectivityDescription)
            await ui.setProvisionedInfo(info)
        }
    }
    
    func setSessionState(_ newState: MCSessionState) {
        sessionState = newState
        Task {
            if newState == .connected {
                lastConnectedAt = .now
                await send(message: ProvisionMessage())
            }
            await ui.setState(state, connectivityDescription: connectivityDescription)
        }
    }
    
    func updateUI() {
        Task {
            await ui.setState(state, connectivityDescription: connectivityDescription)
        }
    }
    
    func appearedInBrowser() {
        visibleInBrowser = true
        updateUI()
    }
    
    func disappearedFromBrowser() {
        visibleInBrowser = false
        updateUI()
    }
    
    public nonisolated static func == (lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
        lhs.peerID == rhs.peerID
    }
    
    public nonisolated static func < (lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
        lhs.peerID < rhs.peerID
    }
}
