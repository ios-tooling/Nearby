//
//  ContentView.swift
//  NearbyTestHarness
//
//  Created by Ben Gottlieb on 3/24/25.
//

import Nearby
import Suite

struct ContentView: View {
    var nearbyUI = NearbySession.UI.instance
	
    var body: some View {
        VStack {
			Text(nearbyUI.isActive ? "Active" : "Idle")
			AsyncButton(nearbyUI.isActive ? "Stop" : "Start") {
				if nearbyUI.isActive {
					await NearbySession.instance.stop()
				} else {
					await NearbySession.instance.start()
				}
			}
			
			AsyncButton("Update Discovery Info") {
				await NearbyDevice.local.setProvisionedInfo(["Date": Date.now])
			}
			
			VisibleDevicesList()
        }
        .padding()
		.task { @NearbyActor in
			NearbyDevice.local.setDiscoveryInfo(["Test": "Name"])
			NearbyDevice.local.setProvisionedInfo(["Paired": "Yes"])
			await NearbySession.instance.start()
		}
    }
}

#Preview {
    ContentView()
}
