//
//  Logger.swift
//
//  Created by Ben Gottlieb on 5/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation

public class Logger {
	public struct Notifications {
		public static let logged = Notification.Name("logged-event")
	}
	
	public static let instance = Logger()
	let semaphore = DispatchSemaphore(value: 1)
	
	public var logs: [String] = []
	public var echo = false
	
	public func log(_ string: String) {
		self.semaphore.wait()
		logs.append(string)
		self.semaphore.signal()
		
		DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.logged, object: string)}
		if self.echo { print("######### " + string) }
	}
	
	public func clear() {
		self.semaphore.wait()
		self.logs.removeAll()
		self.semaphore.signal()
	}
}
