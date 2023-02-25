//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 2/25/23.
//

import Foundation

extension String {
	enum BonjourValidationError: Error { case tooShort, noInfoDictionary, noBonjourServicesDictionary, noTCPID, noUDPID }
	
	func validateBonjourServiceType() throws {
		if count >= 15 { throw BonjourValidationError.tooShort }
		
		guard let dict = Bundle.main.infoDictionary else { throw BonjourValidationError.noInfoDictionary }
		guard let services = dict["NSBonjourServices"] as? [String] else { throw BonjourValidationError.noBonjourServicesDictionary }
		
		let tcpID = "_" + self + "._tcp"
		let udpID = "_" + self + "._udp"

		if !services.contains(tcpID) { throw BonjourValidationError.noTCPID }
		if !services.contains(udpID) { throw BonjourValidationError.noUDPID }
	}
}
