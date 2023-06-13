//
//  NearbyDevice+Types.swift
//  
//
//  Created by Ben Gottlieb on 6/13/23.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit
import Studio

extension NearbyDevice {
	struct Keys {
		static let name = "name"
		static let idiom = "idiom"
		static let unique = "unique"
	}
}

extension MCSessionState: CustomStringConvertible {
	public var description: String {
		switch self {
		case .connected: return "*conected*"
		case .notConnected: return "*notConnected*"
		case .connecting: return "*connecting*"
		@unknown default: return "*unknown*"
		}
	}
}

extension NearbyDevice {
	public struct Notifications {
		public static let deviceChangedState = Notification.Name("device-state-changed")
		public static let deviceConnected = Notification.Name("device-connected")
		public static let deviceConnectedWithInfo = Notification.Name("device-connected-with-info")
		public static let deviceDisconnected = Notification.Name("device-disconnected")
		public static let deviceChangedInfo = Notification.Name("device-changed-info")
	}
	
	public static let localDevice = NearbySession.deviceClass.init(asLocalDevice: true)
	
	public enum State: Int, Comparable, CustomStringConvertible, Codable { case none, found, invited, connecting, connected, disconnected
		public var description: String {
			switch self {
			case .none: return "None"
			case .found: return "Found"
			case .invited: return "Invited"
			case .connected: return "Connected"
			case .connecting: return "Connecting"
			case .disconnected: return "Disconnected"
			}
		}
		
		public var color: UXColor {
			switch self {
			case .none: return .gray
			case .found: return .yellow
			case .invited: return .orange
			case .connected: return .green
			case .connecting: return .blue
			case .disconnected: return .gray
			}
		}
		
		public var contrastingColor: UXColor {
			switch self {
			case .found, .invited, .connected: return .black
			default: return .white
			}
		}
		
		public static func < (lhs: State, rhs: State) -> Bool { return lhs.rawValue < rhs.rawValue }

	}
}
