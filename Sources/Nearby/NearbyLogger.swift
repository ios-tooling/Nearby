//
//  NearbyLogger.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import OSLog
import Suite

public class NearbyLogger {
	public struct Notifications {
		public static let logged = Notification.Name("logged-event")
	}
	
	public static let instance = NearbyLogger()
	let semaphore = DispatchSemaphore(value: 1)
	let logger = Logger(subsystem: "Nearby", category: "comms")
	
	public var logs: [String] = []
	public var echo = CommandLine.bool(for: "debug_nearby")
	
	
	public func log(_ string: String, onlyWhenDebugging: Bool = false) {
		if onlyWhenDebugging, !Gestalt.isAttachedToDebugger { return }
		self.semaphore.wait()
		logs.append(string)
		self.semaphore.signal()
		
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.logged, object: string)}
		if self.echo { logger.warning("\(string)") }
	}

	public func error(_ error: Error, _ string: String) {
		self.semaphore.wait()
		logs.append("\(string): \(error)")
		self.semaphore.signal()
		
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.logged, object: string)}
		if self.echo { logger.error("\(string): \(error)") }
	}

	public func clear() {
		self.semaphore.wait()
		self.logs.removeAll()
		self.semaphore.signal()
	}
}
