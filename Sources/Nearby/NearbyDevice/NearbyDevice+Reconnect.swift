//
//  NearbyDevice+Reconnection.swift
//
//
//  Created by Ben Gottlieb on 7/4/23.
//

import Foundation

extension NearbyDevice {
	func attemptReconnection() {
		reconnectionDelay = min(reconnectionDelay * 1.5, 20)
		
		reconnectionTask?.cancel()
		
		switch state {
		case .provisioned:
			reconnectionDelay = 0.5

		case .none:
			reconnectionDelay = 0.5
			
		default:
			reconnectionTask = Task {
				try? await Task.sleep(nanoseconds: UInt64(reconnectionDelay * 1_000_000_000))
				connect()
			}
		}
	}

}
