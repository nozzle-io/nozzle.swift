import Foundation
import Nozzle

let sender = try Sender.create(name: "swift_sender", applicationName: "SwiftExample")
print("Sender created: \(sender.info.name)")

let width: UInt32 = 512
let height: UInt32 = 512
let totalFrames = 300

for i in 0..<totalFrames {
    let frame = try sender.acquireWritableFrame(width: width, height: height, format: .rgba8Unorm)
    let pixels = try frame.lockWritablePixels()

    let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: pixels.byteCount)
    for y in 0..<Int(pixels.height) {
        for x in 0..<Int(pixels.width) {
            let offset = (y * Int(pixels.rowBytes)) + (x * 4)
            let t = Double(i) / Double(totalFrames)
            let cx = Double(x) / Double(width)
            let cy = Double(y) / Double(height)
            buffer[offset]     = UInt8(clamping: Int(255 * t * cx))
            buffer[offset + 1] = UInt8(clamping: Int(128 * cy))
            buffer[offset + 2] = UInt8(clamping: Int(255 * (1.0 - t)))
            buffer[offset + 3] = 255
        }
    }

    pixels.unlock()
    try sender.commitFrame(frame)

    if i % 30 == 0 {
        print("Frame \(i)/\(totalFrames)")
    }

    Thread.sleep(forTimeInterval: 0.1)
}

print("Sender done")
