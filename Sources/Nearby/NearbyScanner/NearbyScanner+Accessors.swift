//
//  NearbyScanner+Accessors.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/24/25.
//

import Foundation

extension NearbyScanner {
    func setIsBrowsing(_ browsing: Bool) {
        isBrowsing = browsing
    }
    
    func setIsAdvertising(_ advertising: Bool) {
        isAdvertising = advertising
    }
    
    func setRecentError(_ error: Error?) {
        recentError = error
    }
}
