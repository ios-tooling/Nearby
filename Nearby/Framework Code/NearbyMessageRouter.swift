//
//  MessageRouter.swift
//
//  Created by Ben Gottlieb on 5/19/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation

public protocol NearbyMessageRouter {
	func route(_ payload: NearbyMessagePayload, from device: NearbyDevice) -> NearbyMessage?

}

class InternalRouter: NearbyMessageRouter {
	static let instance = InternalRouter()
	
	func route(_ payload: NearbyMessagePayload, from device: NearbyDevice) -> NearbyMessage? {
		guard let kind = NearbySystemMessage.Kind(rawValue: payload.command) else { return nil }
		
		do {
			switch kind {
			case .ping: Logger.instance.log("PING")
			case .disconnect: device.disconnect()
				
			case .deviceInfo:
				if let message: NearbySystemMessage.DeviceInfo = try payload.reconstitute() {
					device.deviceInfo = message.deviceInfo
					return message
				}
			}

			let message: NearbySystemMessage? = try payload.reconstitute()
			return message
		} catch {
			Logger.instance.log("Failed to reconstitute a \(payload.command) message")
		}
		
		return nil
	}
	
}
