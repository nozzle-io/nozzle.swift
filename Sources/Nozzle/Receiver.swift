import CNozzle

public final class Receiver {
    internal var ptr: OpaquePointer?

    private init(ptr: OpaquePointer?) {
        self.ptr = ptr
    }

    deinit {
        if let ptr { nozzle_receiver_destroy(ptr) }
    }

    public static func create(name: String, applicationName: String, receiveMode: ReceiveMode = .latestOnly) throws -> Receiver {
        return try Receiver.create(ReceiverDesc(
            name: name,
            applicationName: applicationName,
            receiveMode: receiveMode
        ))
    }

    public static func create(_ desc: ReceiverDesc) throws -> Receiver {
        var receiverPtr: OpaquePointer?

        try desc.name.withCString { namePtr in
            try desc.applicationName.withCString { appNamePtr in
                var cDesc = CNozzle.NozzleReceiverDesc()
                cDesc.name = namePtr
                cDesc.application_name = appNamePtr
                cDesc.receive_mode = desc.receiveMode.cValue

                try check(nozzle_receiver_create(&cDesc, &receiverPtr))
            }
        }

        guard let ptr = receiverPtr else {
            throw NozzleError.unknown
        }
        return Receiver(ptr: ptr)
    }

    public func acquireFrame(timeoutMs: UInt64 = 0) throws -> Frame {
        var cDesc = CNozzle.NozzleAcquireDesc()
        cDesc.timeout_ms = timeoutMs

        var framePtr: OpaquePointer?
        try check(nozzle_receiver_acquire_frame(ptr, &cDesc, &framePtr))
        guard let fptr = framePtr else {
            throw NozzleError.unknown
        }
        return Frame(ptr: fptr, isWritable: false)
    }

    public var connectedInfo: ConnectedSenderInfo? {
        var cInfo = CNozzle.NozzleConnectedSenderInfo()
        let result = nozzle_receiver_get_connected_info(ptr, &cInfo)
        guard result.rawValue == 0 else { return nil }
        return ConnectedSenderInfo(cInfo)
    }

    public var isConnected: Bool {
        return connectedInfo != nil
    }
}
