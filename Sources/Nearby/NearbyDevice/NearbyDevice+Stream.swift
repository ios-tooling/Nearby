//
//  NearbyDevice+Stream.swift
//  
//
//  Created by Ben Gottlieb on 8/23/23.
//

import Foundation
import MultipeerConnectivity
import CrossPlatformKit
import Studio

extension NearbyDevice: StreamDelegate {
	func handleIncomingStreamedData() {
		
	}
	
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode {
		case .hasBytesAvailable:
			if let incomingStream {
				if let total = incomingStream.read() {
					if total > 0 { handleIncomingStreamedData() }
				} else {
					closeStream()
				}
			}
			
		case .endEncountered:
			closeStream()
			
		case .hasSpaceAvailable:
			break
			
		default:
			print("Stream event: \(eventCode)")
		}
	}
}

extension NearbyDevice {
	enum NearbyDeviceError: Error { case failedToCreateStream }
	public func startStream(named name: String = "nearby-stream") throws -> OutputStream {
		if let outgoingStream { return outgoingStream }
		guard let stream = try session?.startStream(withName: name, toPeer: peerID) else { throw NearbyDeviceError.failedToCreateStream }
		stream.delegate = self
		stream.schedule(in: RunLoop.main, forMode: .default)
		stream.open()
		
		outgoingStream = stream
		
		return stream
	}
	
	public func send(data: Data) throws {
		try outgoingStream?.writeCountedData(data: data)
	}
	
	func session(didReceive stream: InputStream, withName streamName: String) {
		if let incomingStream {
			print("Already have a stream (\(incomingStream) for \(name)")
			return
		}
		incomingStream = IncomingStream(stream: stream) { data in
			print("Got data: \(data.count) bytes")
		}
		stream.delegate = self
		stream.schedule(in: RunLoop.main, forMode: .default)
		stream.open()
		objectWillChange.sendOnMain()
	}
	
	public func closeStream() {
		if outgoingStream == nil, incomingStream == nil { return }
		print("Closing the streams for \(displayName)")
		outgoingStream?.close()
		incomingStream?.close()
		outgoingStream = nil
		incomingStream = nil
		objectWillChange.sendOnMain()
	}
}
