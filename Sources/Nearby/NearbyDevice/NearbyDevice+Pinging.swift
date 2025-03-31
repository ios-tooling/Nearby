//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/30/25.
//

import Foundation
import MultipeerConnectivity

extension NearbyDevice {
    func didReceivePing() {
        NearbyLog.log(.pingReceived(peerID))
        lastPingReceivedAt = .now
        timeoutTask?.cancel()
        timeoutTask = nil
        Task { @MainActor in
            await ui.lastPingReceivedAt = .now
        }
    }
    
    static nonisolated let pingDuration = 3.0
    func sendPing() {
        guard NearbySession.instance.devicePingTimeout != nil else { return }
        
        pingTask = Task {
            try await Task.sleep(for: .seconds(Self.pingDuration))
            NearbyLog.log(.pingSent(peerID))
            await send(message: PingMessage())
            sendPing()
            if timeoutTask == nil {
                setupPingTimeout()
            }
        }
    }
    
    func stopPinging() {
        pingTask?.cancel()
        pingTask = nil
        timeoutTask?.cancel()
        timeoutTask = nil
    }
    
    func setupPingTimeout() {
        guard let timeout = NearbySession.instance.devicePingTimeout else { return }
        timeoutTask = Task {
            try await Task.sleep(for: .seconds(timeout))
            didDisconnect()
            NearbyLog.log(.deviceTimedOut(peerID))
        }
    }
}
