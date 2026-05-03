import CNozzle

public final class Frame {
    internal var ptr: OpaquePointer?
    internal let isWritable: Bool
    private var released = false

    internal init(ptr: OpaquePointer?, isWritable: Bool) {
        self.ptr = ptr
        self.isWritable = isWritable
    }

    deinit {
        release()
    }

    public var info: FrameInfo {
        var cInfo = CNozzle.NozzleFrameInfo()
        let result = nozzle_frame_get_info(ptr, &cInfo)
        guard result.rawValue == 0 else {
            return FrameInfo(frameIndex: 0, timestampNs: 0, width: 0, height: 0, format: .unknown, droppedFrameCount: 0)
        }
        return FrameInfo(cInfo)
    }

    public func lockPixels() throws -> MappedPixels {
        var cPixels = CNozzle.NozzleMappedPixels()
        try check(nozzle_frame_lock_pixels(ptr, &cPixels))
        guard cPixels.data != nil else {
            throw NozzleError.unknown
        }
        return MappedPixels(framePtr: ptr, pixels: cPixels, isWritable: false)
    }

    public func lockWritablePixels() throws -> MappedPixels {
        var cPixels = CNozzle.NozzleMappedPixels()
        try check(nozzle_frame_lock_writable_pixels(ptr, &cPixels))
        guard cPixels.data != nil else {
            throw NozzleError.unknown
        }
        return MappedPixels(framePtr: ptr, pixels: cPixels, isWritable: true)
    }

    public func release() {
        guard !released, let p = ptr else { return }
        nozzle_frame_release(p)
        ptr = nil
        released = true
    }

    public func copyToNativeTexture(_ nativeTexture: UnsafeMutableRawPointer, width: UInt32, height: UInt32, format: TextureFormat) throws {
        try check(nozzle_frame_copy_to_native_texture(ptr, nativeTexture, width, height, format.cValue))
    }
}

public final class MappedPixels {
    private let framePtr: OpaquePointer?
    private let isWritable: Bool
    private var unlocked = false

    public let data: UnsafeMutableRawPointer
    public let rowBytes: UInt32
    public let width: UInt32
    public let height: UInt32
    public let format: TextureFormat

    internal init(framePtr: OpaquePointer?, pixels: CNozzle.NozzleMappedPixels, isWritable: Bool) {
        self.framePtr = framePtr
        self.isWritable = isWritable
        self.data = pixels.data!
        self.rowBytes = pixels.row_bytes
        self.width = pixels.width
        self.height = pixels.height
        self.format = TextureFormat(pixels.format)
    }

    deinit {
        unlock()
    }

    public func unlock() {
        guard !unlocked, let ptr = framePtr else { return }
        if isWritable {
            nozzle_frame_unlock_writable_pixels(ptr)
        } else {
            nozzle_frame_unlock_pixels(ptr)
        }
        unlocked = true
    }

    public var byteCount: Int {
        return Int(rowBytes) * Int(height)
    }
}
