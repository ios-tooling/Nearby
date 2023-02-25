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
			self.rsvpCheckTimer?.invalidate()
			return
		}
		
		if self.rsvpCheckTimer != nil { return }
		DispatchQueue.main.async {
			self.rsvpCheckTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(NearbyDevice.checkRSVPStatus), userInfo: nil, repeats: true)
		}
	}
	
	@objc func checkRSVPStatus() {
		if self.session?.connectedPeers.contains(self.peerID) == true {
			self.state = .connected
		}
	}
}
