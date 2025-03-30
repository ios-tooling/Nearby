//
//  VisibleDevicesList.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/28/25.
//

import SwiftUI

public struct VisibleDevicesList: View {
    var sessionUI = NearbySession.UI.instance
    
    public init() { }
    
    public var body: some View {
        List {
            ForEach(sessionUI.devices) { device in
                Row(device: device)
            }
        }
    }
    
    struct Row: View {
        var device: NearbyDevice.UI
        var body: some View {
            VStack {
                Text(device.id.description)
                HStack {
                    Text(device.connectivityDescription)
                        .foregroundStyle(Color(uxColor: device.state.color))
                }
                Text(device.discoveryInfo.description)
                Text(device.provisionedInfo.description)
                
                HStack {
                    Button("Disconnect") { device.disconnect() }
                        .disabled(!device.canDisconnect)
                    
                    Button("Reconnect") { device.reconnect() }
                        .disabled(!device.canReconnect)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VisibleDevicesList()
}
