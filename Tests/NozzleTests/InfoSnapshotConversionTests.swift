import CNozzle
import XCTest
@testable import Nozzle

// Synthetic conversion only: these imported C values are not native getter results.
final class InfoSnapshotConversionTests: XCTestCase {
    func testEmptyAndNulTerminatedTuple() {
        var raw = NozzleSenderInfoSnapshot()
        XCTAssertEqual(snapshotString(raw.name), "")
        raw.name.0 = 65
        raw.name.1 = 0
        raw.name.2 = 66
        XCTAssertEqual(snapshotString(raw.name), "A")
    }

    func testNonterminatedTupleStaysWithinItsBounds() {
        var raw = NozzleSenderInfoSnapshot()
        withUnsafeMutableBytes(of: &raw.name) { bytes in
            for i in bytes.indices { bytes[i] = 65 }
        }
        XCTAssertEqual(snapshotString(raw.name), String(repeating: "A", count: 64))
        XCTAssertEqual(snapshotString(raw.application_name), "")
    }

    func testSignedBytesDecodeUtf8WithReplacement() {
        var raw = NozzleSenderInfoSnapshot()
        raw.name.0 = CChar(bitPattern: 0xf0)
        raw.name.1 = CChar(bitPattern: 0x9f)
        raw.name.2 = CChar(bitPattern: 0x9a)
        raw.name.3 = CChar(bitPattern: 0x80)
        raw.name.4 = CChar(bitPattern: 0xff)
        XCTAssertEqual(snapshotString(raw.name), "\u{1f680}\u{fffd}")
    }

    private func storeString<T>(_ value: String, in tuple: inout T) {
        // Test fixture helper, restricted to the imported inline char tuples below.
        let encoded = Array(value.utf8)
        withUnsafeMutableBytes(of: &tuple) { bytes in
            precondition(encoded.count < bytes.count)
            for i in bytes.indices { bytes[i] = 0 }
            for (i, byte) in encoded.enumerated() { bytes[i] = byte }
        }
    }

    func testSenderSnapshotOwnsDecodedIdentity() {
        var raw = NozzleSenderInfoSnapshot()
        storeString("sender-\u{1f680}", in: &raw.name)
        storeString("app-\u{65e5}\u{672c}", in: &raw.application_name)
        storeString("sender-id", in: &raw.id)
        raw.backend = NOZZLE_BACKEND_METAL
        let info = SenderInfo(raw)
        raw = NozzleSenderInfoSnapshot()
        XCTAssertEqual(info.name, "sender-\u{1f680}")
        XCTAssertEqual(info.applicationName, "app-\u{65e5}\u{672c}")
        XCTAssertEqual(info.id, "sender-id")
        XCTAssertEqual(info.backend, .metal)
    }

    func testConnectionSnapshotPreservesStateAndAllMappedMetadata() {
        var raw = NozzleConnectedSenderSnapshot()
        storeString("last-name", in: &raw.name)
        storeString("last-app", in: &raw.application_name)
        storeString("last-id", in: &raw.id)
        raw.connected = 1
        raw.backend = NOZZLE_BACKEND_METAL
        raw.width = 65
        raw.height = 3
        raw.format = NOZZLE_FORMAT_RGBA16_FLOAT
        raw.semantic_format = NOZZLE_FORMAT_RGB16_FLOAT
        raw.estimated_fps = 59.25
        raw.frame_counter = (UInt64(1) << 40) + 7
        raw.last_update_time_ns = UInt64.max - 9
        let connected = ConnectionSnapshot(raw)
        XCTAssertTrue(connected.connected)
        raw.connected = 0
        let disconnected = ConnectionSnapshot(raw)
        XCTAssertFalse(disconnected.connected)
        raw = NozzleConnectedSenderSnapshot()
        XCTAssertEqual(connected.info, disconnected.info)
        for snapshot in [connected, disconnected] {
            let info = snapshot.info
            XCTAssertEqual(info.name, "last-name")
            XCTAssertEqual(info.applicationName, "last-app")
            XCTAssertEqual(info.id, "last-id")
            XCTAssertEqual(info.backend, .metal)
            XCTAssertEqual(info.width, 65)
            XCTAssertEqual(info.height, 3)
            XCTAssertEqual(info.format, .rgba16Float)
            XCTAssertEqual(info.semanticFormat, .rgb16Float)
            XCTAssertEqual(info.estimatedFps, 59.25)
            XCTAssertEqual(info.frameCounter, (UInt64(1) << 40) + 7)
            XCTAssertEqual(info.lastUpdateTimeNs, UInt64.max - 9)
        }
    }
}
