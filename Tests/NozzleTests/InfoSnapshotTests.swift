import Foundation
import Nozzle
import XCTest

// Real same-process Metal metadata only: no pixel, cross-process, or concurrency claims.
final class InfoSnapshotTests: XCTestCase {
    func testObservedSenderClosureReportsDisconnected() throws {
        let name = "swift-info-\(ProcessInfo.processInfo.processIdentifier)-closed-\u{65e5}\u{672c}\u{1f680}"
        let application = "snapshot-\u{65e5}\u{672c}-\u{1f3a5}"
        var sender: Sender? = try Sender.create(name: name, applicationName: application)
        weak var weakSender = sender
        let senderInfo = try XCTUnwrap(sender?.info)
        XCTAssertEqual(senderInfo.backend, .metal)
        let receiver = try Receiver.create(name: name, applicationName: "InfoSnapshotTests")
        let retained = try XCTUnwrap(receiver.connectedInfo)
        XCTAssertTrue(receiver.isConnected)
        let initial = try XCTUnwrap(receiver.connectionSnapshot)
        XCTAssertTrue(initial.connected)
        XCTAssertEqual(initial.info, retained)
        XCTAssertEqual(retained.id, senderInfo.id)
        XCTAssertFalse(retained.id.isEmpty)

        // No frames or strong temporary Sender bindings keep the native sender alive.
        sender = nil
        XCTAssertNil(weakSender, "sender must actually deinitialize before acquisition")
        guard weakSender == nil else { return }
        // Core checks the closed marker before waiting, including at timeout zero.
        XCTAssertThrowsError(try receiver.acquireFrame(timeoutMs: 0)) { error in
            print("SWIFT_INFO_CLOSURE acquire_error=\(error)")
            XCTAssertEqual(error as? NozzleError, .senderClosed)
        }
        let lastKnown = try XCTUnwrap(receiver.connectedInfo)
        XCTAssertEqual(lastKnown.name, name)
        XCTAssertEqual(lastKnown.applicationName, application)
        XCTAssertEqual(lastKnown.id, retained.id)
        XCTAssertEqual(lastKnown.backend, .metal)
        XCTAssertEqual(retained.name, name)
        XCTAssertEqual(retained.applicationName, application)
        let connected = receiver.isConnected
        print("SWIFT_INFO_CLOSURE last_known_id=\(lastKnown.id) connected=\(connected)")
        XCTAssertFalse(connected, "observed SenderClosed must report disconnected")
        let closed = try XCTUnwrap(receiver.connectionSnapshot)
        XCTAssertFalse(closed.connected)
        XCTAssertEqual(closed.info, lastKnown)
        XCTAssertTrue(initial.connected, "retained snapshot must not change")
        XCTAssertEqual(initial.info, retained)
    }

    func testMetadataRemainsOwnedAfterBothHandlesDeinitialize() throws {
        let name = "swift-info-\(ProcessInfo.processInfo.processIdentifier)-owned-\u{65e5}\u{672c}\u{1f680}"
        let application = "snapshot-\u{65e5}\u{672c}-\u{1f3a5}"
        var sender: Sender? = try Sender.create(name: name, applicationName: application)
        weak var weakSender = sender
        let senderInfo = try XCTUnwrap(sender?.info)
        XCTAssertEqual(senderInfo.backend, .metal)
        var receiver: Receiver? = try Receiver.create(name: name, applicationName: "InfoSnapshotTests")
        weak var weakReceiver = receiver
        let receiverInfo = try XCTUnwrap(receiver?.connectedInfo)
        let snapshot = try XCTUnwrap(receiver?.connectionSnapshot)
        XCTAssertTrue(snapshot.connected)
        XCTAssertEqual(snapshot.info, receiverInfo)
        XCTAssertEqual(receiverInfo.backend, .metal)
        XCTAssertEqual(sender?.info, senderInfo)
        XCTAssertEqual(receiver?.connectedInfo, receiverInfo)

        receiver = nil
        sender = nil
        XCTAssertNil(weakReceiver, "receiver must actually deinitialize")
        XCTAssertNil(weakSender, "sender must actually deinitialize")
        guard weakReceiver == nil, weakSender == nil else { return }

        XCTAssertEqual(senderInfo.name, name)
        XCTAssertEqual(senderInfo.applicationName, application)
        XCTAssertEqual(receiverInfo.name, name)
        XCTAssertEqual(receiverInfo.applicationName, application)
        XCTAssertFalse(senderInfo.id.isEmpty)
        XCTAssertEqual(receiverInfo.id, senderInfo.id)
        XCTAssertTrue(snapshot.connected)
        XCTAssertEqual(snapshot.info, receiverInfo)
        print("SWIFT_INFO_OWNED PASS retained UTF-8 identity after both handles deinitialized")
    }
}
