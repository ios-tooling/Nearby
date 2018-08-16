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
		
		do {
			switch kind {
			case .ping: Logger.instance.log("PING")
			case .disconnect: device.disconnect()
				
			case .deviceInfo:
				if let message: PeerSystemMessage.DeviceInfo = try payload.reconstitute() {
					device.deviceInfo = message.deviceInfo
					return message
				}
			}

			let message: PeerSystemMessage? = try payload.reconstitute()
			return message
		} catch {
			Logger.instance.log("Failed to reconstitute a \(payload.command) message")
		}
		
		return nil
	}
	
}
