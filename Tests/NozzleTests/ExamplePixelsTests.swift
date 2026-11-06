import CNozzle
import ExamplePixels
import Foundation
import XCTest
@testable import Nozzle

final class ExamplePixelsTests: XCTestCase {
    func testExampleSenderAgainstNativeReader() throws {
        for width: UInt32 in [65, 641] {
            for requested: TextureFormat in [.rgba8Unorm, .bgra8Unorm] {
                let name = "swift-example-\(UUID().uuidString)"
                let sender = try Sender.create(name: name, applicationName: "example-test")
                defer { withExtendedLifetime(sender) {} }
                XCTAssertEqual(sender.info.backend, .metal)
                let receiver = try nativeReceiver(name)
                defer { nozzle_receiver_destroy(receiver) }
                let frame = try sender.acquireWritableFrame(width: width, height: 3, format: requested)
                let pixels = try frame.lockWritablePixels()
                XCTAssertEqual(pixels.format, .bgra8Unorm, "Pinned Metal RGBA8/BGRA8 storage contract")
                let written = writeExampleGradient(pixels, frameIndex: 1, totalFrames: 4)
                pixels.unlock()
                guard written else {
                    try sender.discardFrame(frame)
                    XCTFail("Example rejected supported mapping")
                    continue
                }
                try sender.commitFrame(frame)
                var acquire = NozzleAcquireDesc()
                acquire.timeout_ms = 1000
                var received: OpaquePointer?
                try check(nozzle_receiver_acquire_frame(receiver, &acquire, &received))
                let receivedFrame = try XCTUnwrap(received)
                defer { nozzle_frame_release(receivedFrame) }
                var native = NozzleMappedPixels()
                try check(nozzle_frame_lock_pixels_with_origin(receivedFrame, NOZZLE_ORIGIN_TOP_LEFT, &native))
                defer { nozzle_frame_unlock_pixels(receivedFrame) }
                XCTAssertEqual(native.format, NOZZLE_FORMAT_BGRA8_UNORM)
                XCTAssertEqual(native.width, width)
                XCTAssertEqual(native.height, 3)
                XCTAssertGreaterThanOrEqual(native.row_stride_bytes, Int64(width) * 4)
                let bytes = try XCTUnwrap(native.data).assumingMemoryBound(to: UInt8.self)
                // Independent C metadata interpretation, not the example's decoder.
                let red = native.format == NOZZLE_FORMAT_BGRA8_UNORM ? 2 : 0
                let blue = native.format == NOZZLE_FORMAT_BGRA8_UNORM ? 0 : 2
                for (x, y, expected): (Int, Int, [UInt8]) in [
                    (0, 0, [0, 0, 191, 255]),
                    (Int(width) - 1, 2, [width == 65 ? 62 : 63, 85, 191, 255]),
                ] {
                    let offset = y * Int(native.row_stride_bytes) + x * 4
                    let actual = [bytes[offset + red], bytes[offset + 1], bytes[offset + blue], bytes[offset + 3]]
                    XCTAssertEqual(actual, expected, "native reader width=\(width), x=\(x), y=\(y)")
                }
                print("EXAMPLE_NATIVE sender requested=\(requested) mapped=\(native.format.rawValue) width=\(width) stride=\(native.row_stride_bytes)")
            }
        }
    }

    func testExampleReceiverAgainstNativeWriter() throws {
        for width: UInt32 in [65, 641] {
            for requested in [NOZZLE_FORMAT_RGBA8_UNORM, NOZZLE_FORMAT_BGRA8_UNORM] {
                let name = "native-example-\(UUID().uuidString)"
                let sender = try nativeSender(name)
                defer { nozzle_sender_destroy(sender) }
                var info = NozzleSenderInfoSnapshot()
                try check(nozzle_sender_get_info_snapshot(sender, &info))
                XCTAssertEqual(info.backend, NOZZLE_BACKEND_METAL)
                let receiver = try Receiver.create(name: name, applicationName: "example-test")
                var writable: OpaquePointer?
                try check(nozzle_sender_acquire_writable_frame(sender, width, 3, requested, &writable))
                let frame = try XCTUnwrap(writable)
                defer { nozzle_frame_release(frame) }
                var native = NozzleMappedPixels()
                try check(nozzle_frame_lock_writable_pixels_with_origin(frame, NOZZLE_ORIGIN_TOP_LEFT, &native))
                XCTAssertEqual(native.format, NOZZLE_FORMAT_BGRA8_UNORM)
                let bytes = try XCTUnwrap(native.data).assumingMemoryBound(to: UInt8.self)
                let red = native.format == NOZZLE_FORMAT_BGRA8_UNORM ? 2 : 0
                let blue = native.format == NOZZLE_FORMAT_BGRA8_UNORM ? 0 : 2
                for y in 0..<Int(native.height) {
                    for x in 0..<Int(native.width) {
                        let offset = y * Int(native.row_stride_bytes) + x * 4
                        bytes[offset + red] = 17
                        bytes[offset + 1] = 63
                        bytes[offset + blue] = 201
                        bytes[offset + 3] = 143
                    }
                }
                try check(nozzle_frame_unlock_writable_pixels_checked(frame))
                try check(nozzle_sender_commit_frame(sender, frame))
                let received = try receiver.acquireFrame(timeoutMs: 1000)
                let pixels = try received.lockPixels()
                defer { pixels.unlock() }
                XCTAssertEqual(pixels.format, .bgra8Unorm)
                XCTAssertEqual(readExampleRGBA(pixels), [17, 63, 201, 143])
                print("EXAMPLE_NATIVE receiver requested=\(requested.rawValue) mapped=\(pixels.format) width=\(width) stride=\(pixels.rowBytes)")
            }
        }
    }

    func testPaddedRGBAAndBGRAFixtures() {
        for format in [NOZZLE_FORMAT_RGBA8_UNORM, NOZZLE_FORMAT_BGRA8_UNORM] {
            withFixture(format) { pixels, bytes in
                XCTAssertTrue(writeExampleGradient(pixels, frameIndex: 1, totalFrames: 4))
                let red = format == NOZZLE_FORMAT_BGRA8_UNORM ? 2 : 0
                let blue = format == NOZZLE_FORMAT_BGRA8_UNORM ? 0 : 2
                XCTAssertEqual(bytes[red], 0)
                XCTAssertEqual(bytes[blue], 191)
                XCTAssertEqual(bytes[32 + 4 + red], 31)
                XCTAssertEqual(bytes[32 + 4 + 1], 64)
                XCTAssertEqual(bytes[32 + 4 + blue], 191)
                for index in Array(8..<32) + Array(40..<64) {
                    XCTAssertEqual(bytes[index], 0xA5, "Padding modified at \(index)")
                }
                // Independent bytes for the reader, not the writer output above.
                bytes[red] = 17; bytes[1] = 63; bytes[blue] = 201; bytes[3] = 143
                XCTAssertEqual(readExampleRGBA(pixels), [17, 63, 201, 143])
            }
        }
    }

    func testUnsupportedLayoutsAreRejectedWithoutWriting() {
        for format in [NOZZLE_FORMAT_UNKNOWN, NOZZLE_FORMAT_R8_UNORM, NOZZLE_FORMAT_RGBA16_FLOAT,
                       NOZZLE_FORMAT_RGBA32_FLOAT, NOZZLE_FORMAT_RGBA8_SRGB, NOZZLE_FORMAT_BGRA8_SRGB] {
            withFixture(format) { pixels, bytes in
                XCTAssertFalse(writeExampleGradient(pixels, frameIndex: 1, totalFrames: 4), "\(format.rawValue)")
                XCTAssertNil(readExampleRGBA(pixels), "\(format.rawValue)")
                XCTAssertTrue(bytes.allSatisfy { $0 == 0xA5 }, "Unsupported layout modified")
            }
        }
    }

    func testDiscardReturnsReservedSlot() throws {
        let sender = try Sender.create(name: "discard-\(UUID().uuidString)", applicationName: "example-test", ringBufferSize: 2)
        for _ in 0..<8 {
            let frame = try sender.acquireWritableFrame(width: 65, height: 3, format: .rgba8Unorm)
            try sender.discardFrame(frame)
        }
    }

    private func nativeReceiver(_ name: String) throws -> OpaquePointer {
        var receiver: OpaquePointer?
        try name.withCString { namePointer in
            try "native-reader".withCString { application in
                var desc = NozzleReceiverDesc()
                desc.name = namePointer
                desc.application_name = application
                desc.receive_mode = NOZZLE_RECEIVE_LATEST_ONLY
                try check(nozzle_receiver_create(&desc, &receiver))
            }
        }
        return try XCTUnwrap(receiver)
    }

    private func nativeSender(_ name: String) throws -> OpaquePointer {
        var sender: OpaquePointer?
        try name.withCString { namePointer in
            try "native-writer".withCString { application in
                var desc = NozzleSenderDesc()
                desc.name = namePointer
                desc.application_name = application
                desc.ring_buffer_size = 3
                desc.fallback_flags_valid = 1
                desc.fallback_flags = UInt32(NOZZLE_FALLBACK_STORAGE_COMPATIBLE)
                try check(nozzle_sender_create(&desc, &sender))
            }
        }
        return try XCTUnwrap(sender)
    }

    private func withFixture(_ format: NozzleTextureFormat, _ body: (MappedPixels, UnsafeMutableBufferPointer<UInt8>) -> Void) {
        var storage = [UInt8](repeating: 0xA5, count: 64)
        storage.withUnsafeMutableBufferPointer { bytes in
            var native = NozzleMappedPixels()
            native.data = UnsafeMutableRawPointer(bytes.baseAddress!)
            native.row_stride_bytes = 32
            native.width = 2
            native.height = 2
            native.format = format
            let pixels = MappedPixels(framePtr: nil, pixels: native, isWritable: true)
            body(pixels, bytes)
        }
    }
}
