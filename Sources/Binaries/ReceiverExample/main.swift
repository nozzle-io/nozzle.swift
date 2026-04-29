import Foundation
import Nozzle

let receiver = try Receiver.create(name: "swift_sender", applicationName: "SwiftViewer")
print("Receiver created, waiting for sender...")

let iterations = 900 // ~30 seconds at 33ms per iteration
var received = 0

for _ in 0..<iterations {
    do {
        let frame = try receiver.acquireFrame(timeoutMs: 1000)
        let info = frame.info

        let pixelInfo: String
        if let pixels = try? frame.lockPixels() {
            let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: min(4, pixels.byteCount))
            if pixels.byteCount >= 4 {
                pixelInfo = "rgba=\(buffer[0]),\(buffer[1]),\(buffer[2]),\(buffer[3])"
            } else {
                pixelInfo = "no pixel data"
            }
            pixels.unlock()
        } else {
            pixelInfo = "could not lock pixels"
        }

        print("Frame \(info.frameIndex): \(info.width)x\(info.height) \(pixelInfo)")
        received += 1
    } catch {
        print("Acquire error: \(error)")
    }

    Thread.sleep(forTimeInterval: 0.033)
}

print("Receiver done (received \(received) frames)")
