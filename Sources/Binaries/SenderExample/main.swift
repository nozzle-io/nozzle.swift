import Foundation
import Nozzle
import ExamplePixels

let sender = try Sender.create(name: "swift_sender", applicationName: "SwiftExample")
print("Sender created: \(sender.info.name)")

let width: UInt32 = 512
let height: UInt32 = 512
let totalFrames = 300

for i in 0..<totalFrames {
    let frame = try sender.acquireWritableFrame(width: width, height: height, format: .rgba8Unorm)
    let pixels = try frame.lockWritablePixels()

    let written = writeExampleGradient(pixels, frameIndex: i, totalFrames: totalFrames)
    pixels.unlock()
    guard written else {
        try sender.discardFrame(frame)
        print("Unsupported mapped layout: \(pixels.format)")
        break
    }
    try sender.commitFrame(frame)

    if i % 30 == 0 {
        print("Frame \(i)/\(totalFrames)")
    }

    Thread.sleep(forTimeInterval: 0.1)
}

print("Sender done")
