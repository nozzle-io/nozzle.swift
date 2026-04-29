import CNozzle

public final class Device {
    internal var ptr: OpaquePointer?

    private init(ptr: OpaquePointer?) {
        self.ptr = ptr
    }

    deinit {
        if let ptr { nozzle_device_destroy(ptr) }
    }

    public static func defaultDevice() throws -> Device {
        var devicePtr: OpaquePointer?
        try check(nozzle_device_get_default(&devicePtr))
        guard let ptr = devicePtr else {
            throw NozzleError.unknown
        }
        return Device(ptr: ptr)
    }
}
