//
//  NearbyTestHarnessTests.swift
//  NearbyTestHarnessTests
//
//  Created by Ben Gottlieb on 3/24/25.
//

import Testing
import Foundation
@testable import Nearby

struct NearbyTestHarnessTests {
    struct TestMessage: NearbyMessage, Equatable {
        static var kind = "TestMessage"
        
        var color = "red"
        var count = 4
    }
    
    struct TestMessage2: NearbyMessage, Equatable {
        static var kind = "TestMessage2"
        
        var color = "red"
        var count = 4
    }
    
    @Test func testNearbyMessages() async throws {
        TestMessage.register()
        TestMesage2.register()
        
        let message = TestMessage()
        let messageData = try Data(message: message)
        let newMessage: TestMessage = try messageData.extract()
        
        #expect(message == newMessage)
        
        let someMessage = MessageManager.instance.decodeMessage(from: messageData)
        #expect(someMessage as? TestMessage == message)
    }

}
