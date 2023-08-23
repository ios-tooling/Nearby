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
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode {
		case .hasBytesAvailable:
				break
			
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
	public func startStream(named name: String = "nearby-stream") throws -> OutputStream {
		if let outgoingStream { return outgoingStream }
		guard let stream = try session?.startStream(withName: name, toPeer: peerID) else { throw NearbyDeviceError.failedToCreateStream }
		stream.delegate = self
		stream.schedule(in: RunLoop.main, forMode: .common)
		stream.open()
		
		outgoingStream = stream
		
		return stream
	}
	
	func received(streamData data: Data) {
		print("Got data: \(data.count) bytes")
	}
	
	public func send(data: Data) throws {
		guard let outgoingStream else {
			print("No outgoing stream")
			throw NearbyDeviceError.noOutgoingStream
		}
		print("Sending \(data.count) bytes")
		try outgoingStream.writeCountedData(data: data)
	}
	
	func session(didReceive stream: InputStream, withName streamName: String) {
		if let incomingStream {
			print("Already have a stream (\(incomingStream) for \(name)")
			return
		}
		DispatchQueue.main.async {
			self.incomingStream = IncomingStream(stream: stream, device: self)
			self.objectWillChange.send()
		}
	}
	
	public func closeStream() {
		if outgoingStream == nil, incomingStream == nil { return }
		
		if let outgoingStream {
			print("Closing outgoing stream: \(outgoingStream), \(outgoingStream.streamStatus)")
			outgoingStream.remove(from: RunLoop.main, forMode: .default)
			outgoingStream.close()
		}

		if let incomingStream {
			print("Closing outgoing stream: \(incomingStream.stream?.description ?? ""), \(incomingStream.stream?.streamStatus) \(incomingStream.stream.hasBytesAvailable)")
			incomingStream.close()
		}
		outgoingStream = nil
		incomingStream = nil
		objectWillChange.sendOnMain()
	}
}
