//
//  NearbyDevice+Types.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import Suite
import CrossPlatformKit

extension NearbyDevice {
    public enum State: Int, Comparable, CustomStringConvertible, RawCodable, Sendable { case unknown, hidden, visible, invited, connecting, connected, provisioned, disconnected
        
        public var canConnect: Bool {
            switch self {
            case .unknown, .visible, .disconnected, .hidden: return true
            default: return false
            }
        }
        
        public var description: String {
            switch self {
            case .unknown: "Unknown"
            case .visible: "Visible"
            case .invited: "Invited"
            case .connected: "Connected"
            case .provisioned: "Provisioned"
            case .connecting: "Connecting"
            case .disconnected: "Disconnected"
            case .hidden: "Hidden"
            }
        }
        
        public var color: UXColor {
            switch self {
            case .unknown: .gray
            case .disconnected: .red
            case .visible: .orange
            case .invited: .yellow
            case .connecting: .green
            case .connected: .blue
            case .provisioned: .purple
            case .hidden: .black
            }
        }
        
        public var isConnected: Bool {
            switch self {
            case .connected, .provisioned: true
            default: false
            }
        }
        
        public static func < (lhs: State, rhs: State) -> Bool { lhs.rawValue < rhs.rawValue }
    }
}
