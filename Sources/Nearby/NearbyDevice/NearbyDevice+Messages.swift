//
//  NearbyDevice+Messages.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import Foundation

extension NearbyDevice {
    public func send<Message: NearbyMessage>(message: Message) async {
        do {
            print("Sending \(type(of: message)) to \(peerID.displayName)")
            try session?.send(Data(message: message), toPeers: [peerID], with: .reliable)
        } catch {
            print("Failed to send \(message) to \(peerID.displayName): \(error.localizedDescription)")
        }
    }
}
