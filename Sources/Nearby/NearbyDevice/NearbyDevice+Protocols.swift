//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/13/23.
//

import Foundation

public protocol NearbyDeviceDelegate: AnyObject {
	func didReceive(message: NearbyMessage, from: NearbyDevice)
	func didReceiveFirstInfo(from: NearbyDevice)
	func didChangeInfo(from: NearbyDevice)
	func didChangeState(for: NearbyDevice)
}

