//
//  Computed.swift
//
//
//  Created by Ben Gottlieb on 6/13/23.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit
import Studio
import SwiftUI

extension NearbyDevice: ObservableObject, Identifiable {
	public var id: String { uniqueID }
	public var filename: String { id.idBasedFilename }
}

public extension NearbyDevice {
	var attributedDescription: NSAttributedString {
		if isLocalDevice { return NSAttributedString(string: "Local Device", attributes: [.foregroundColor: UXColor.black]) }
		return NSAttributedString(string: displayName, attributes: [.foregroundColor: stateColor, .font: UXFont.boldSystemFont(ofSize: 14)])
	}
	
	override var description: String {
		var string = "\(displayName) [\(state.description)] "
		if let disconnectedAt {
			string += "disconnected at \(disconnectedAt.formatted()) "
		}
		if isIPad { string += ", iPad" }
		if isIPhone { string += ", iPhone" }
		if isMac { string += ", Mac" }
		return string
	}

	var imageName: String {
		if idiom == "pad" { return "ipad" }
		if idiom == "watch" { return "applewatch" }
		if idiom == "mac" { return "desktopcomputer" }
		return "iphone"
	}
	
	static func <(lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
		if lhs.displayName != rhs.displayName { return lhs.displayName < rhs.displayName }
		if lhs.idiom != rhs.idiom { return lhs.idiom < rhs.idiom }
		return lhs.peerID.id < rhs.peerID.id
	}
}
