//
//  MessageRouter.swift
//  SpotEm
//
//  Created by Ben Gottlieb on 5/19/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation

public protocol PeerMessageRouter {
	func route(_ payload: PeerMessagePayload, from device: PeerDevice) -> PeerMessage?

}

class InternalRouter: PeerMessageRouter {
	static let instance = InternalRouter()
	
	func route(_ payload: PeerMessagePayload, from device: PeerDevice) -> PeerMessage? {
		guard let kind = PeerSystemMessage.Kind(rawValue: payload.command) else { return nil }
		
		switch kind {
		case .ping:
			Logger.instance.log("PING")
//		case .match:
//			if let match = message.match {
//				SpotEmGame.instance.received(match: match, from: device)
//			}
			
//		case .selectedSigils:
//			if let data = message.data, let payload = try? JSONDecoder().decode(Message.SigilsSelectedPayload.self, from: data) {
//				Logger.instance.log("Selected \(payload.sigils)")
//				SpotEmGame.instance.received(selectedSigils: payload.sigils, from: payload.playerID)
//			}
			
		case .disconnect:
			device.disconnect()
		}

		do {
			let message: PeerSystemMessage? = try payload.reconstitute()
			return message
		} catch {
			Logger.instance.log("Failed to reconstitute a \(payload.command) message")
		}
		
		return nil
	}
	
}
