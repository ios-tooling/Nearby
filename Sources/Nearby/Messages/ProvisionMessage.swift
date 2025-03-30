//
//  ProvisionMessage.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import Suite

public struct ProvisionMessage: NearbyMessage {
    public static let kind = "provision"
    
    var info: CodableJSONDictionary = [:]
    
    @NearbyActor init() {
        info = .init(NearbyDevice.local.provisionedInfo ?? [:])
    }
}
