//
//  Computed.swift
//
//
//  Created by Ben Gottlieb on 6/13/23.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit
import Suite
import SwiftUI

extension NearbyDevice: ObservableObject, Identifiable {
	public var id: String { uniqueID }
	public var filename: String { id.idBasedFilename }
}

public extension NearbyDevice {
	var attributedDescription: NSAttributedString {
		if isLocalDevice { return NSAttributedString(string: "Local Device", attributes: [.foregroundColor: UXColor.black]) }
		return NSAttributedString(string: name, attributes: [.foregroundColor: stateColor, .font: UXFont.boldSystemFont(ofSize: 14)])
	}
	
	override var description: String {
		var string = "\(name) [\(state.description)] "
		if let disconnectedAt {
			string += "disconnected at \(disconnectedAt.localTimeString(date: .none)) "
		}
		if isIPad { string += ", iPad" }
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
		if lhs.name != rhs.name { return lhs.name < rhs.name }
		if lhs.idiom != rhs.idiom { return lhs.idiom < rhs.idiom }
		return lhs.peerID.id < rhs.peerID.id
	}
}
