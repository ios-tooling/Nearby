//
//  NearbyMessageManager.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import Foundation
import MultipeerConnectivity

@NearbyActor public class NearbyMessageManager {
    static let instance = NearbyMessageManager()
    
    enum NearbyMessageManagerError: Error { case unknownMessageKind }
    
    var registeredMessageKinds: [String: any NearbyMessage.Type] = [:]
    
    func register(kind: any NearbyMessage.Type) {
        registeredMessageKinds[kind.kind] = kind
    }
    
    func decodeMessage(from data: Data) throws -> any NearbyMessage {
        let kindString = try data.messageKind
        guard let kind = registeredMessageKinds[kindString] else { throw NearbyMessageManagerError.unknownMessageKind }
        
        return try decodeMessage(from: data, kind: kind)
    }
    
    func decodeMessage<Message: NearbyMessage>(from data: Data, kind: Message.Type) throws -> Message {
        let message: Message = try data.extract()
        return message
    }
    
    func received(data: Data, from peerID: MCPeerID) {
        if let kind = try? data.messageKind {
            print("Received \(kind)")
        }
        if let message: PairMessage = try? data.extract() {
            NearbySession.instance[peerID]?.updateProvisionedInfo(message.info.dictionary)
        }
    }
}
