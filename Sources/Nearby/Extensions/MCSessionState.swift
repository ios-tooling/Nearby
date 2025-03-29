//
//  MCSessionState.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import Foundation
import MultipeerConnectivity

extension MCSessionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connected: "connected"
        case .connecting: "connecting"
        case .notConnected: "not connected"
        default: "unknown"
        }
    }
}
