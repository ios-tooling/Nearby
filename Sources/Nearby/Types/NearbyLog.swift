//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import MultipeerConnectivity
import SwiftUI

enum NearbyLoggedEvent {
    case browserFoundPeer(MCPeerID, [String: String]?), browserLostPeer(MCPeerID), browserFailedToStart(Error)
    case advertisingStarted(Date, String), advertisingStopped(Date), advertisingFailedToStart(Error)
    case browsingStarted(Date), browsingStopped(Date)
    case peerStateChanged(MCPeerID, MCSessionState)
    case reinvited(MCPeerID)
    case reconnected(MCPeerID)
    case disconnectedFrom(MCPeerID)
    case foundInvitablePeer(MCPeerID)
    case createdNewDevice(MCPeerID)
    case sendingMessage(String, MCPeerID)
    case receivedMessage(String, MCPeerID)
    case pingSent(MCPeerID)
    case pingReceived(MCPeerID)
    case deviceTimedOut(MCPeerID)

    var text: String {
        switch self {
        case .browserFoundPeer(let id, _): "found peer: \(id.displayName)"
        case .browserLostPeer(let id): "lost peer: \(id.displayName)"
        case .browserFailedToStart(let error): "failed to start: \(error)"
        case .advertisingStarted(let date, _): "advertising started: \(date.formatted())"
        case .advertisingStopped(let date): "advertising stopped: \(date.formatted())"
        case .advertisingFailedToStart(let error): "advertising failed to start: \(error)"
        case .browsingStarted(let date): "browsing started at \(date.formatted())"
        case .browsingStopped(let date): "browsing stopped at \(date.formatted())"
        case .peerStateChanged(let id, let state): "peer state of \(id.displayName) is now: \(state.description))"
        case .reinvited(let id): "reinvited: \(id.displayName)"
        case .reconnected(let id): "reconnected: \(id.displayName)"
        case .disconnectedFrom(let id): "disconnected from: \(id.displayName)"
        case .foundInvitablePeer(let id): "invited: \(id.displayName)"
        case .createdNewDevice(let id): "created new device for: \(id.displayName)"
        case .sendingMessage(let kind, let id): "sending message: \(kind) to: \(id.displayName)"
        case .receivedMessage(let kind, let id): "received message: \(kind) from: \(id.displayName)"
        case .pingSent(let id): "sent ping to \(id.displayName)"
        case .pingReceived(let id): "received ping from \(id.displayName)"
        case .deviceTimedOut(let id): "device timed out: \(id.displayName)"
        }
    }
}

@NearbyActor class NearbyLog {
    static let instance = NearbyLog()
    
    var events: [NearbyLoggedEvent] = []
    
    func log(event: NearbyLoggedEvent) {
        events.append(event)
        let events = events
        Task { @MainActor in UI.instance.updateLogs(events) }
    }
    
    static nonisolated func log(_ event: NearbyLoggedEvent) {
        Task { @NearbyActor in NearbyLog.instance.log(event: event) }
    }
    
    @MainActor @Observable public class UI {
        public static let instance = UI()
        
        public var events: [NearbyLoggedEvent] = []
        
        func updateLogs(_ logs: [NearbyLoggedEvent]) {
            events = logs
        }
    }
}

