import CNozzle

public final class Sender {
    internal var ptr: OpaquePointer?

    private init(ptr: OpaquePointer?) {
        self.ptr = ptr
    }

    deinit {
        if let ptr { nozzle_sender_destroy(ptr) }
    }

    public static func create(name: String, applicationName: String, ringBufferSize: UInt32 = 3, allowFormatFallback: Bool = true) throws -> Sender {
        return try Sender.create(SenderDesc(
            name: name,
            applicationName: applicationName,
            ringBufferSize: ringBufferSize,
            allowFormatFallback: allowFormatFallback
        ))
    }

    public static func create(_ desc: SenderDesc) throws -> Sender {
        var senderPtr: OpaquePointer?

        try desc.name.withCString { namePtr in
            try desc.applicationName.withCString { appNamePtr in
                var cDesc = CNozzle.NozzleSenderDesc()
                cDesc.name = namePtr
                cDesc.application_name = appNamePtr
                cDesc.ring_buffer_size = desc.ringBufferSize
                cDesc.fallback_flags_valid = 1
                cDesc.fallback_flags = desc.allowFormatFallback ? 3 : 0

                try check(nozzle_sender_create(&cDesc, &senderPtr))
            }
        }

        guard let ptr = senderPtr else {
            throw NozzleError.unknown
        }
        return Sender(ptr: ptr)
    }

    public var info: SenderInfo {
        var cInfo = CNozzle.NozzleSenderInfo()
        let result = nozzle_sender_get_info(ptr, &cInfo)
        guard result.rawValue == 0 else {
            return SenderInfo(name: "", applicationName: "", id: "", backend: .unknown)
        }
        return SenderInfo(cInfo)
    }

    public func acquireWritableFrame(width: UInt32, height: UInt32, format: TextureFormat) throws -> Frame {
        var framePtr: OpaquePointer?
        try check(nozzle_sender_acquire_writable_frame(ptr, width, height, format.cValue, &framePtr))
        guard let fptr = framePtr else {
            throw NozzleError.unknown
        }
        return Frame(ptr: fptr, isWritable: true)
    }

    public func commitFrame(_ frame: Frame) throws {
        guard let fptr = frame.ptr else {
            throw NozzleError.invalidArgument
        }
        try check(nozzle_sender_commit_frame(ptr, fptr))
    }

    public func publishNativeTexture(_ nativeTexture: UnsafeMutableRawPointer, width: UInt32, height: UInt32, format: TextureFormat) throws {
        try check(nozzle_sender_publish_native_texture(ptr, nativeTexture, width, height, format.cValue))
    }
}
