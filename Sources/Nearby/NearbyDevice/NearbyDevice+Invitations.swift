//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/28/25.
//

import MultipeerConnectivity

extension NearbyDevice {
    func invite() async {
        if await peerID > NearbyDevice.local.peerID { return }
        
        NearbySession.instance.scanner.scanner.invitePeer(peerID, to: NearbySession.session!, withContext: Data(), timeout: 30.0)
    }
}
