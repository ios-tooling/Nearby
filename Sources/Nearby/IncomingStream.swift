//
//  IncomingStream.swift
//  
//
//  Created by Ben Gottlieb on 8/23/23.
//

import Foundation

public class IncomingStream {
	var stream: InputStream!
	public var buffers: [[UInt8]]
	var totalReceived = 0
	var bufferReadOffset = 0
	var bufferWriteOffset = 0
	var received: (Data) -> Void
	
	var bufferIndex = 0
	var buffer: [UInt8] {
		get { buffers[bufferIndex] }
		set { buffers[bufferIndex] = newValue }
	}

	init(stream: InputStream, size: Int = NearbySession.instance.expectedStreamDataSize, received: @escaping (Data) -> Void) {
		self.stream = stream
		buffers = [ [UInt8](repeating: 0, count: size), [UInt8](repeating: 0, count: size) ]
		self.received = received
	}
	
	func close() {
		stream?.close()
		stream = nil
	}
	
	func read() -> Int? {
		var total = 0
		
		while stream.hasBytesAvailable {
			let batchCount = buffer.withUnsafeMutableBufferPointer { buffer in
				buffer.withMemoryRebound(to: UInt8.self) { bytes in
					guard let ptr = bytes.baseAddress else { return -1 }
					return stream.read(ptr, maxLength: buffer.count)
				}
			}
			
			if batchCount == -1 {
				print("Failed to read data from stream")
				return nil
			}
			
			bufferWriteOffset += batchCount
			total += batchCount
			
			let currentChunkSize = buffer.withUnsafeBytes { bytes in
				bytes.load(fromByteOffset: bufferReadOffset, as: UInt32.self)
			}
			
			if bufferWriteOffset >= (currentChunkSize + 4) {			// we've gotten enough data to read a chunk in
				let data = Data(bytesNoCopy: &buffer[bufferReadOffset + 4], count: Int(currentChunkSize), deallocator: .none)
				received(data)
				bufferReadOffset += Int(currentChunkSize + 4)
				swapBuffers()
			}
		}

		totalReceived += total
		return total
	}
	
	func swapBuffers() {
		if bufferIndex == 0 {		// move the rest of 0 into the beginning of 1
			for i in bufferReadOffset..<bufferWriteOffset {
				buffers[1][i - bufferReadOffset] = buffers[0][i]
			}
		} else {
			for i in bufferReadOffset..<bufferWriteOffset {
				buffers[0][i - bufferReadOffset] = buffers[1][i]
			}
		}
		
		bufferWriteOffset -= bufferReadOffset
		bufferReadOffset = 0
		bufferIndex = bufferIndex == 1 ? 0 : 1
	}
}
