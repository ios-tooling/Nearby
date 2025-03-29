//
//  String.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/27/25.
//

import Foundation

#if canImport(UIKit)
    import UIKit
#endif

extension String {
    enum BonjourValidationError: Error { case tooLong, noInfoDictionary, noBonjourServicesDictionary, noTCPID, noUDPID }
    
    static var serviceType: String {
        get throws {
            guard let dict = Bundle.main.infoDictionary else { throw BonjourValidationError.noInfoDictionary }
            guard let services = dict["NSBonjourServices"] as? [String] else {
                throw BonjourValidationError.noBonjourServicesDictionary
            }
            
            guard let tcp = services.first(where: { $0.hasSuffix("._tcp")}) else { throw BonjourValidationError.noTCPID }
            return String(tcp.replacingOccurrences(of: "._tcp", with: "").dropFirst())
        }
    }
    
    func validateBonjourServiceType() throws {
        if count >= 15 { throw BonjourValidationError.tooLong }
        
        guard let dict = Bundle.main.infoDictionary else { throw BonjourValidationError.noInfoDictionary }
        guard let services = dict["NSBonjourServices"] as? [String] else {
            nearbyLogger.error("Please add an NSBonjourServices array to your info.plist. It should have two items for each service, each prefaced with '_' and suffixed with either '._tcp' or '_udp'")
            throw BonjourValidationError.noBonjourServicesDictionary
        }
        
        let tcpID = "_" + self + "._tcp"
        let udpID = "_" + self + "._udp"

        if !services.contains(tcpID) { throw BonjourValidationError.noTCPID }
        if !services.contains(udpID) { throw BonjourValidationError.noUDPID }
    }
    
    static var localDeviceName: String {
        get {
            #if os(macOS)
                ProcessInfo.processInfo.hostName
            #elseif os(iOS)
                DispatchQueue.main.sync { UIDevice.current.name }
            #else
                ProcessInfo.processInfo.hostName
            #endif
        }
    }
}

