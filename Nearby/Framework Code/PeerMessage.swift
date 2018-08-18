//
//  PeerMessage.Payload.swift
//  VisionTools
//
//  Created by Ben Gottlieb on 8/3/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation

public protocol PeerMessage: class, Codable {
	var command: String { get }
}

public class PeerSystemMessage: PeerMessage {
	public enum Kind: String, Codable { case ping = "*system-ping*", disconnect = "*system-disconnect*", deviceInfo = "*device-info*" }
	
	public static var ping: PeerSystemMessage = PeerSystemMessage(kind: Kind.ping)
	public static var disconnect: PeerSystemMessage = PeerSystemMessage(kind: Kind.disconnect)

	public var kind: Kind
	public var command: String { return self.kind.rawValue }
	
	init(kind: Kind) {
		self.kind = kind
	}
}

extension PeerSystemMessage {
	class DeviceInfo: PeerMessage {
		var command: String { return self.kind.rawValue }
		
		enum CodableKeys: String, CodingKey { case deviceInfo }
		var deviceInfo: [String: String]?
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKeys.self)
			try? container.encode(self.deviceInfo, forKey: .deviceInfo)
		}
		public var kind = PeerSystemMessage.Kind.deviceInfo

		required init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKeys.self)
			self.deviceInfo = try container.decode([String: String].self, forKey: .deviceInfo)
		}
		
		init() {
			self.deviceInfo = PeerSession.instance.localDeviceInfo
		}
	}
}

public struct PeerMessagePayload {
	public let identifier: String
	public let command: String
	public let className: String
	public let data: Data
	
	init?<MessageType: PeerMessage>(command: String? = nil, message: MessageType) {
		self.className = NSStringFromClass(MessageType.self)
		self.identifier = UUID().uuidString
		self.command = command ?? message.command
		guard let data = try? JSONEncoder().encode(message), self.className.count <= 255 else {
			self.data = Data()
			return nil
		}
		self.data = data
	}
	
	public func reconstitute<MessageType: PeerMessage>() throws -> MessageType? {
		let cls = NSClassFromString(self.className) as? MessageType.Type
		if cls != MessageType.self { return nil }
		return try JSONDecoder().decode(MessageType.self, from: self.data)
	}
	
	var payloadData: Data {
		var data = Data()
		
		let strings = [self.identifier, self.command, self.className]
		data.append(UInt8(strings.count))

		for string in strings {
			let utf = string.utf8
			data.append(UInt8(utf.count))
			data.append([UInt8](utf), count: utf.count)
		}

		data.append(self.data)
		return data
	}
	
	init?(data: Data) {
		var strings: [String] = []
		var remainingData: Data?

		data.withUnsafeBytes { (raw: UnsafePointer<UInt8>) in
			let bytes = [UInt8](UnsafeBufferPointer(start: raw, count: data.count))
			let stringCount = Int(bytes[0])
			var offset = 1
			
			for _ in 0..<stringCount {
				let length = Int(bytes[offset])
				let stringBuffer = bytes[(offset + 1)..<Int(length + offset + 1)]
				if let string = String(bytes: stringBuffer, encoding: .utf8) {
					strings.append(string)
				}
				offset += length + 1
			}
			remainingData = data.subdata(in: offset..<data.count)
		}
		
		let stringCount = 3
		guard strings.count >= stringCount, let payload = remainingData else {
			self.className = ""
			self.identifier = ""
			self.data = Data()
			return nil
		}
		
		self.identifier = strings[0]
		self.command = strings[1]
		self.className = strings[2]
		self.data = payload
	}
}

