//
//  Stream.swift
//
//
//  Created by Ben Gottlieb on 8/22/23.
//

import Foundation

extension OutputStream {
	enum StreamError: Error { case failedToWrite, failedToDecodeOutgoingData }
	
	func writeCountedData(data: Data) throws {
		try write(int: Int32(data.count))
		try write(data: data)
	}

	@discardableResult func write(data: Data) throws -> Int {
		try data.withUnsafeBytes {
			guard let address = $0.bindMemory(to: UInt8.self).baseAddress else { throw StreamError.failedToDecodeOutgoingData }
			return write(address, maxLength: data.count)
		}
	}
	
	@discardableResult func write(int value: Int16) throws -> Bool {
		try withUnsafeBytes(of: value.bigEndian) { bytes in
			guard let address = bytes.bindMemory(to: UInt8.self).baseAddress else { throw StreamError.failedToDecodeOutgoingData }
			let count = write(address, maxLength: 2)
			if count == -1 { throw StreamError.failedToWrite }
			return count == 2
		}
	}
	
	@discardableResult func write(int value: Int32) throws -> Bool {
		try withUnsafeBytes(of: value.bigEndian) { bytes in
			guard let address = bytes.bindMemory(to: UInt8.self).baseAddress else { throw StreamError.failedToDecodeOutgoingData }
			let count = write(address, maxLength: 4)
			if count == -1 { throw StreamError.failedToWrite }
			return count == 4
		}
	}
}
