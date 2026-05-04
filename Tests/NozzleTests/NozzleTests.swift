import XCTest
@testable import Nozzle

final class EnumTests: XCTestCase {
    func testTextureFormatRoundTrip() {
        let formats: [TextureFormat] = [
            .unknown, .r8Unorm, .rg8Unorm, .rgba8Unorm, .bgra8Unorm,
            .rgba8Srgb, .bgra8Srgb, .r16Unorm, .rg16Unorm, .rgba16Unorm,
            .r16Float, .rg16Float, .rgba16Float, .r32Float, .rg32Float,
            .rgba32Float, .r32Uint, .rgba32Uint, .depth32Float,
        ]
        for format in formats {
            let c = format.cValue
            let back = TextureFormat(c)
            XCTAssertEqual(back, format, "Round-trip failed for \(format)")
        }
    }

    func testBackendTypeRoundTrip() {
        let backends: [BackendType] = [.unknown, .d3d11, .metal, .opengl]
        for backend in backends {
            let c = backend.cValue
            let back = BackendType(c)
            XCTAssertEqual(back, backend, "Round-trip failed for \(backend)")
        }
    }

    func testReceiveModeCValues() {
        XCTAssertEqual(ReceiveMode.latestOnly.cValue.rawValue, 0)
        XCTAssertEqual(ReceiveMode.sequentialBestEffort.cValue.rawValue, 1)
    }
}

final class ErrorTests: XCTestCase {
    func testNozzleErrorDescription() {
        XCTAssertEqual(NozzleError.unknown.description, "Unknown error")
        XCTAssertEqual(NozzleError.invalidArgument.description, "Invalid argument")
        XCTAssertEqual(NozzleError.timeout.description, "Timeout")
        XCTAssertEqual(NozzleError.senderNotFound.description, "Sender not found")
    }

    func testNozzleErrorFromRawValue() {
        let cases: [(Int, NozzleError)] = [
            (1, .unknown),
            (2, .invalidArgument),
            (3, .unsupportedBackend),
            (10, .timeout),
            (99, .unknown),
        ]
        for (raw, expected) in cases {
            XCTAssertEqual(NozzleError(rawValue: raw), expected)
        }
    }

    func testNozzleErrorEquatable() {
        XCTAssertEqual(NozzleError.timeout, NozzleError.timeout)
        XCTAssertNotEqual(NozzleError.timeout, NozzleError.senderClosed)
    }
}

final class TypeTests: XCTestCase {
    func testSenderDescDefaults() {
        let desc = SenderDesc(name: "test", applicationName: "app")
        XCTAssertEqual(desc.name, "test")
        XCTAssertEqual(desc.applicationName, "app")
        XCTAssertEqual(desc.ringBufferSize, 3)
        XCTAssertTrue(desc.allowFormatFallback)
    }

    func testReceiverDescDefaults() {
        let desc = ReceiverDesc(name: "test", applicationName: "app")
        XCTAssertEqual(desc.name, "test")
        XCTAssertEqual(desc.applicationName, "app")
        XCTAssertEqual(desc.receiveMode, .latestOnly)
    }

    func testAcquireDescDefaults() {
        let desc = AcquireDesc()
        XCTAssertEqual(desc.timeoutMs, 0)
    }

    func testFrameInfoDefaults() {
        let info = FrameInfo(
            frameIndex: 42,
            timestampNs: 1000,
            width: 1920,
            height: 1080,
            format: .rgba8Unorm,
            droppedFrameCount: 2
        )
        XCTAssertEqual(info.frameIndex, 42)
        XCTAssertEqual(info.width, 1920)
        XCTAssertEqual(info.height, 1080)
        XCTAssertEqual(info.format, .rgba8Unorm)
        XCTAssertEqual(info.droppedFrameCount, 2)
    }

    func testSenderInfoEquality() {
        let a = SenderInfo(name: "s", applicationName: "a", id: "123", backend: .metal)
        let b = SenderInfo(name: "s", applicationName: "a", id: "123", backend: .metal)
        XCTAssertEqual(a, b)
    }

    func testConnectedSenderInfoFields() {
        let info = ConnectedSenderInfo(
            name: "s",
            applicationName: "a",
            id: "id",
            backend: .metal,
            width: 640,
            height: 480,
            format: .bgra8Unorm,
            estimatedFps: 60.0,
            frameCounter: 100,
            lastUpdateTimeNs: 5000
        )
        XCTAssertEqual(info.width, 640)
        XCTAssertEqual(info.estimatedFps, 60.0)
        XCTAssertEqual(info.frameCounter, 100)
    }
}

final class IntegrationTests: XCTestCase {
    func testSenderCreateAndDestroy() throws {
        let sender = try Sender.create(name: "swift-test", applicationName: "NozzleTests")
        let info = sender.info
        XCTAssertEqual(info.name, "swift-test")
        XCTAssertEqual(info.applicationName, "NozzleTests")
        XCTAssertEqual(info.backend, .metal)
    }

    func testReceiverCreateAndDestroy() throws {
        let sender = try Sender.create(name: "receiver-test", applicationName: "NozzleTests")
        defer { _ = sender }

        let receiver = try Receiver.create(name: "receiver-test", applicationName: "NozzleTests")
        XCTAssertTrue(receiver.isConnected)
        let info = receiver.connectedInfo
        XCTAssertEqual(info?.name, "receiver-test")
        XCTAssertEqual(info?.applicationName, "NozzleTests")
        XCTAssertEqual(info?.backend, .metal)
    }

    func testSenderPublishWritableFrame() throws {
        let sender = try Sender.create(name: "frame-test", applicationName: "NozzleTests")

        let frame = try sender.acquireWritableFrame(width: 256, height: 256, format: .rgba8Unorm)
        let info = frame.info
        XCTAssertEqual(info.width, 256)
        XCTAssertEqual(info.height, 256)
        // Metal fallback: rgba8 → bgra8 for 8-bit IOSurface
        XCTAssertNotEqual(info.format, .unknown)

        try sender.commitFrame(frame)
    }

    func testPixelLockAndUnlock() throws {
        let sender = try Sender.create(name: "pixel-test", applicationName: "NozzleTests")

        let frame = try sender.acquireWritableFrame(width: 64, height: 64, format: .rgba8Unorm)
        let pixels = try frame.lockWritablePixels()

        XCTAssertEqual(pixels.width, 64)
        XCTAssertEqual(pixels.height, 64)
        // Metal fallback: rgba8 → bgra8 for 8-bit IOSurface
        XCTAssertNotEqual(pixels.format, .unknown)
        XCTAssertGreaterThan(pixels.rowBytes, 0)
        XCTAssertGreaterThan(pixels.byteCount, 0)
        XCTAssertNotNil(pixels.data)

        pixels.unlock()
    }

    func testDiscoveryEnumerate() throws {
        let senders = try Discovery.enumerateSenders()
        XCTAssertNotNil(senders)
    }

    func testCrossProcessTransfer() throws {
        let senderName = "cross-process-\(UInt64.random(in: 0...UInt64.max))"

        let sender = try Sender.create(name: senderName, applicationName: "NozzleTests-Sender")

        let receiver = try Receiver.create(name: senderName, applicationName: "NozzleTests-Receiver")

        let frame = try sender.acquireWritableFrame(width: 128, height: 128, format: .rgba8Unorm)
        try sender.commitFrame(frame)

        let receivedFrame = try receiver.acquireFrame(timeoutMs: 2000)
        let info = receivedFrame.info
        XCTAssertEqual(info.width, 128)
        XCTAssertEqual(info.height, 128)
        // Metal fallback: rgba8 → bgra8 for 8-bit IOSurface
        XCTAssertNotEqual(info.format, .unknown)
        XCTAssertEqual(info.frameIndex, 1)
    }
}
