//
//  IncomingStream.swift
//  
//
//  Created by Ben Gottlieb on 8/23/23.
//

import Foundation

public class IncomingStream: NSObject, StreamDelegate {
	var stream: InputStream!
	var buffer: [UInt8]
	var currentChunk: [UInt8]
	var currentChunkSize = 0
	var currentChunkRead = 0
	var totalReceived = 0
	var bufferReadOffset = 0
	var bufferWriteOffset = 0
	weak var device: NearbyDevice?
	
	init(stream: InputStream, size: Int = NearbySession.instance.expectedStreamDataSize, device: NearbyDevice) {
		self.stream = stream
		buffer = [UInt8](repeating: 0, count: size)
		currentChunk = [UInt8](repeating: 0, count: size)
		self.device = device
		
		super.init()
		stream.delegate = self

		stream.schedule(in: RunLoop.main, forMode: .common)
		stream.open()

	}
	
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode {
		case .hasBytesAvailable:
			_ = read()
			
		case .endEncountered:
			device?.closeStream()
			
		case .hasSpaceAvailable:
			break
			
		default:
			print("Stream event: \(eventCode)")
		}
	}

	func close() {
		stream?.remove(from: RunLoop.main, forMode: .default)
		stream?.close()
		stream = nil
	}
	
	@discardableResult public func read() -> Int? {
		var total = 0
		
		while true {
			let batchCount = buffer.withUnsafeMutableBufferPointer { buffer in
				buffer.withMemoryRebound(to: UInt8.self) { bytes in
					guard let ptr = bytes.baseAddress else { return -1 }
					return stream.read((ptr + bufferWriteOffset), maxLength: buffer.count)
				}
			}
			
			if batchCount == 0 { break }
			
			if batchCount == -1 {
				print("Failed to read data from stream")
				return nil
			}
			
			bufferWriteOffset += batchCount
			total += batchCount
			
			while true {
				if currentChunkSize == 0 {
					let unreadBytes = bufferWriteOffset - bufferReadOffset
					if unreadBytes < 4 {
						for i in 0..<unreadBytes {
							buffer[i] = buffer[bufferReadOffset + i]
						}
						bufferReadOffset = 0
						bufferWriteOffset = unreadBytes
						break
					}
					currentChunkSize = Int(buffer.withUnsafeBytes { bytes in
						bytes.loadUnaligned(fromByteOffset: bufferReadOffset, as: UInt32.self)
					}.bigEndian)
					currentChunkRead = 0
					bufferReadOffset += 4
				}
				
				let availableBytes = bufferWriteOffset - bufferReadOffset
				while availableBytes > currentChunk.count - currentChunkRead {
					currentChunk += [UInt8](repeating: 0, count: currentChunk.count)
				}
				
				let bytesAvailable = bufferWriteOffset - bufferReadOffset
				let bytesToCopy = min(bytesAvailable, currentChunkSize - currentChunkRead)
				for i in 0..<bytesToCopy {
					currentChunk[currentChunkRead + i] = buffer[bufferReadOffset + i]
				}

				bufferReadOffset += bytesToCopy
				currentChunkRead += bytesToCopy
				
				if currentChunkRead == currentChunkSize {
					let data = Data(bytesNoCopy: &currentChunk, count: currentChunkSize, deallocator: .none)

					device?.received(streamData: data)
					currentChunkSize = 0
					currentChunkRead = 0
				} else { break }
			}
			
			bufferReadOffset = 0
			bufferWriteOffset = 0
		}
		totalReceived += total

		return total
	}
}
