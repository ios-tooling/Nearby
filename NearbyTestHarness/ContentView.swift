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
			
			VisibleDevicesList()
        }
        .padding()
		.task {
			await NearbySession.instance.start()
		}
    }
}

#Preview {
    ContentView()
}
