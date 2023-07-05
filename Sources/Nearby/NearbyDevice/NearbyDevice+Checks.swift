//
//  Device+Checks.swift
//
//  Created by Ben Gottlieb on 6/2/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension NearbyDevice {
	func checkForRSVP(_ start: Bool) {
		if !start {
			rsvpCheckTimer?.invalidate()
			return
		}
		
		if rsvpCheckTimer != nil { return }
		DispatchQueue.main.async {
			self.rsvpCheckTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(NearbyDevice.checkRSVPStatus), userInfo: nil, repeats: true)
		}
	}
	
	@objc func checkRSVPStatus() {
		if session?.connectedPeers.contains(peerID) == true, state != .provisioned {
			state = deviceInfo == nil ? .connected : .provisioned
		}
	}
}
