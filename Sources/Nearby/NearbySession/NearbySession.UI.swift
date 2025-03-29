//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import SwiftUI

extension NearbySession {
    @MainActor @Observable public class UI {
        public static let instance = UI()
        
        public var isActive = false
        public var devices: [NearbyDevice.UI] = []
        
        func setIsActive(_ active: Bool) {
            isActive = active
        }
        
        @NearbyActor static func setDevices(_ devices: [NearbyDevice]) {
            let deviceUIs = devices.compactMap { $0.ui }
            Task { await UI.instance.setDevices(deviceUIs) }
        }
        
        func setDevices(_ devices: [NearbyDevice.UI]) {
            self.devices = devices
        }
    }
}
