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
    
    static nonisolated let sessionWrapper = NonIsolatedWrapper(MCSession?.none)
    static nonisolated var session: MCSession? {
        get { sessionWrapper.value }
        set { sessionWrapper.value = newValue }
    }
    
    public var isActive: Bool { scanner.isBrowsing || scanner.isAdvertising || Self.session != nil }
    
    @MainActor public static var localDeviceName: String { get { String.localDeviceName }}
    public static var localDeviceInfo: [String: Sendable] = [:]
    
    func updateLocalDeviceInfo(_ info: [String: Sendable]) {
        Self.localDeviceInfo = info
    }
    
    @NearbyActor public static func setup() async {
        NearbyDevice.local = await .init()
    }

    public func start() async {
        do {
            if isActive { return }
            let session = MCSession(peer: await .localPeerID, securityIdentity: nil, encryptionPreference: .optional)
            session.delegate = self
            Self.session = session
            try scanner.startBrowsing()
            try scanner.startAdvertising()
            
            Task { await UI.instance.setIsActive(isActive) }
        } catch {
            print("Failed to start Nearby session")
        }
    }
    
    public func stop() {
        if !isActive { return }
        
        Self.session = nil
        scanner.stopBrowsing()
        scanner.stopAdvertising()

        Task { await UI.instance.setIsActive(isActive) }
    }
}
