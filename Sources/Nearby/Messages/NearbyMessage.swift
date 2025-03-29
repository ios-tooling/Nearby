//
//  File.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import Foundation

public protocol NearbyMessage: Codable, Hashable {
    static var kind: String { get }
}

public extension NearbyMessage {
    @NearbyActor static func register() { NearbyMessageManager.instance.register(kind: self) }
}

extension Data {
    // data layout is 1 byte for kind length, kind, and then json
    
    enum NearbyMessageDataError: Error { case unableToConvertTypeToUTF8, tooShortForKindLength, tooShortForKind, undecodableKind, kindMismatch, unableToDecodeJSON }
    
    var messageKind: String {
        get throws {
            guard count >= 2 else { throw NearbyMessageDataError.tooShortForKind }
            let bytes = [UInt8](self)
            let kindLengthByte = bytes[0]
            guard count > kindLengthByte + 1 else { throw NearbyMessageDataError.tooShortForKindLength}
            let kindBytes = self[1...kindLengthByte]
            guard let kind = String(data: kindBytes, encoding: .utf8) else { throw NearbyMessageDataError.undecodableKind }
            return kind
        }
    }
    
    init<Message: NearbyMessage>(message: Message) throws {
        var data = Data()
        let kind = type(of: message).kind
        guard let ascii = kind.data(using: .utf8) else { throw NearbyMessageDataError.unableToConvertTypeToUTF8 }
        let kindBytes: [UInt8] = [UInt8(kind.utf8.count)]
        data.append(kindBytes, count: kindBytes.count)
        data.append(ascii)
        let json = try JSONEncoder().encode(message)
        data.append(json)
        self = data
    }
    
    func extract<Message: NearbyMessage>() throws -> Message {
        guard count >= 2 else { throw NearbyMessageDataError.tooShortForKind }
        let bytes = [UInt8](self)
        let kindLengthByte = bytes[0]
        guard count > kindLengthByte + 1 else { throw NearbyMessageDataError.tooShortForKindLength}
        let kindBytes = self[1...kindLengthByte]
        guard let kind = String(data: kindBytes, encoding: .utf8) else { throw NearbyMessageDataError.undecodableKind }
        if kind != Message.kind { throw NearbyMessageDataError.kindMismatch }
        let restOfData = self[(kindLengthByte + 1)...]
        return try JSONDecoder().decode(Message.self, from: restOfData)
    }
}
