//
//  NearbyScanner.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import Foundation
import MultipeerConnectivity

@NearbyActor class NearbyScanner: NSObject {
    enum ScannerError: Error { case advertising(Error), browsing(Error) }
    
    var scanner: MCNearbyServiceBrowser
    var advertiser: MCNearbyServiceAdvertiser
    
    var recentError: Error?
    var isAdvertising = false
    var isBrowsing = false
    
    nonisolated static let discoveryInfoDefaultsKey = "discovery-info"
    nonisolated static public var discoveryInfo: [String: String] {
        get { UserDefaults.standard.value(forKey: discoveryInfoDefaultsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: discoveryInfoDefaultsKey)}
    }

    override init() {

        let serviceType = try! String.serviceType
        let peerID = MCPeerID.localPeerID
        
        try! serviceType.validateBonjourServiceType()
        
        scanner = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: Self.discoveryInfo, serviceType: serviceType)

        super.init()

        scanner.delegate = self
        advertiser.delegate = self
    }
    
    func startAdvertising() throws {
        if isAdvertising { return }
        try advertiser.startAdvertisingPeer()
        isAdvertising = true
        NearbyLog.log(.advertisingStarted(.now, try! .serviceType))
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
        NearbyLog.log(.advertisingStopped(.now))
    }
    
    func startBrowsing() {
        if isBrowsing { return }
        scanner.startBrowsingForPeers()
        isBrowsing = true
        NearbyLog.log(.browsingStarted(.now))
    }
    
    func stopBrowsing() {
        scanner.stopBrowsingForPeers()
        isBrowsing = false
        NearbyLog.log(.browsingStopped(.now))
    }
    
    func updateDiscoveryInfo(_ info: [String: String]) async {
        if info == Self.discoveryInfo { return }
        Self.discoveryInfo = info
        await cycleAdvertiser()
    }
    
    func cycleAdvertiser() async {
        await advertiser.stopAdvertisingPeer()
        advertiser = await MCNearbyServiceAdvertiser(peer: .localPeerID, discoveryInfo: Self.discoveryInfo, serviceType: try! .serviceType)
    }
}

