//
//  NearbySession.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import MultipeerConnectivity
import Suite

extension MCSession: @unchecked Sendable { }

@NearbyActor public class NearbySession: NSObject {
    public static let instance = NearbySession()
    
    var scanner = NearbyScanner()
    var devices: Set<NearbyDevice> = [] { didSet {
        UI.setDevices(Array(devices).sorted())
    }}
    var provisionedDevices: Set<NearbyDevice> { devices.filter { $0.state == .provisioned }}
    
    static nonisolated let sessionWrapper = NonIsolatedWrapper([MCPeerID: MCSession]())
    static nonisolated func session(for peerID: MCPeerID) -> MCSession? {
        sessionWrapper.value[peerID]
    }
    static nonisolated func setSession(_ session: MCSession?, for peerID: MCPeerID) {
        sessionWrapper.value[peerID] = session
    }
    
    public var isActive: Bool { scanner.isBrowsing || scanner.isAdvertising }
    public var devicePingTimeout: TimeInterval? = 10
    
    nonisolated public static var localDeviceName: String { get { String.localDeviceName }}
    public static var localDeviceInfo: [String: Sendable] = [:]
    
    func updateLocalDeviceInfo(_ info: [String: Sendable]) {
        Self.localDeviceInfo = info
    }
    
    @NearbyActor public static func setup() async {
    }

    public func start() async {
        do {
            if isActive { return }
            try scanner.startBrowsing()
            try scanner.startAdvertising()
            
            Task { await UI.instance.setIsActive(isActive) }
        } catch {
            print("Failed to start Nearby session")
        }
    }
    
    public func stop() {
        if !isActive { return }
        
        scanner.stopBrowsing()
        scanner.stopAdvertising()

        Task { await UI.instance.setIsActive(isActive) }
    }
}
