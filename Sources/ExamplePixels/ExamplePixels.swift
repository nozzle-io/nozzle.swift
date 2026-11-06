import Nozzle

// Shared by the executables and their native-peer regression tests.
public func writeExampleGradient(_ pixels: MappedPixels, frameIndex: Int, totalFrames: Int) -> Bool {
    guard pixels.width > 0, pixels.height > 0,
          Int(pixels.rowBytes) >= Int(pixels.width) * 4,
          totalFrames > 0, frameIndex >= 0, frameIndex < totalFrames else { return false }
    let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: pixels.byteCount)
    for y in 0..<Int(pixels.height) {
        for x in 0..<Int(pixels.width) {
            let offset = y * Int(pixels.rowBytes) + x * 4
            let t = Double(frameIndex) / Double(totalFrames)
            let cx = Double(x) / Double(pixels.width)
            let cy = Double(y) / Double(pixels.height)
            buffer[offset] = UInt8(clamping: Int(255 * t * cx))
            buffer[offset + 1] = UInt8(clamping: Int(128 * cy))
            buffer[offset + 2] = UInt8(clamping: Int(255 * (1.0 - t)))
            buffer[offset + 3] = 255
        }
    }
    return true
}

public func readExampleRGBA(_ pixels: MappedPixels) -> [UInt8]? {
    guard pixels.width > 0, pixels.height > 0, pixels.rowBytes >= 4 else { return nil }
    let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: pixels.byteCount)
    return [buffer[0], buffer[1], buffer[2], buffer[3]]
}
