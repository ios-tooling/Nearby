//
//  PairMessage.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import Suite

public struct PairMessage: NearbyMessage {
    public static let kind = "pair"
    
    var info: CodableJSONDictionary = [:]
    
    @NearbyActor init() {
        info = .init(NearbyDevice.local.provisionedInfo ?? [:])
    }
}
