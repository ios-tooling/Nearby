//
//  Notifications.swift
//  Nearby_iOS
//
//  Created by Ben Gottlieb on 9/10/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation


extension Notification.Name {
	func post(with device: NearbyDevice) {
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: self, object: device)
		}
	}
}
