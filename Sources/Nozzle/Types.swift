import CNozzle

public struct SenderDesc {
    public var name: String
    public var applicationName: String
    public var ringBufferSize: UInt32
    public var allowFormatFallback: Bool

    public init(
        name: String,
        applicationName: String,
        ringBufferSize: UInt32 = 3,
        allowFormatFallback: Bool = true
    ) {
        self.name = name
        self.applicationName = applicationName
        self.ringBufferSize = ringBufferSize
        self.allowFormatFallback = allowFormatFallback
    }
}

public struct ReceiverDesc {
    public var name: String
    public var applicationName: String
    public var receiveMode: ReceiveMode

    public init(
        name: String,
        applicationName: String,
        receiveMode: ReceiveMode = .latestOnly
    ) {
        self.name = name
        self.applicationName = applicationName
        self.receiveMode = receiveMode
    }
}

public struct AcquireDesc {
    public var timeoutMs: UInt64

    public init(timeoutMs: UInt64 = 0) {
        self.timeoutMs = timeoutMs
    }
}

public struct SenderInfo: Equatable {
    public var name: String
    public var applicationName: String
    public var id: String
    public var backend: BackendType
}

public struct ConnectedSenderInfo: Equatable {
    public var name: String
    public var applicationName: String
    public var id: String
    public var backend: BackendType
    public var width: UInt32
    public var height: UInt32
    public var format: TextureFormat
    public var semanticFormat: TextureFormat
    public var estimatedFps: Double
    public var frameCounter: UInt64
    public var lastUpdateTimeNs: UInt64
}

public struct FrameInfo: Equatable {
    public var frameIndex: UInt64
    public var timestampNs: UInt64
    public var width: UInt32
    public var height: UInt32
    public var format: TextureFormat
    public var semanticFormat: TextureFormat
    public var droppedFrameCount: UInt32
}

internal extension SenderInfo {
    init(_ cValue: CNozzle.NozzleSenderInfo) {
        self.name = cValue.name.flatMap { String(cString: $0) } ?? ""
        self.applicationName = cValue.application_name.flatMap { String(cString: $0) } ?? ""
        self.id = cValue.id.flatMap { String(cString: $0) } ?? ""
        self.backend = BackendType(cValue.backend)
    }
}

internal extension ConnectedSenderInfo {
    init(_ cValue: CNozzle.NozzleConnectedSenderInfo) {
        self.name = cValue.name.flatMap { String(cString: $0) } ?? ""
        self.applicationName = cValue.application_name.flatMap { String(cString: $0) } ?? ""
        self.id = cValue.id.flatMap { String(cString: $0) } ?? ""
        self.backend = BackendType(cValue.backend)
        self.width = cValue.width
        self.height = cValue.height
        self.format = TextureFormat(cValue.format)
        self.semanticFormat = TextureFormat(cValue.semantic_format)
        self.estimatedFps = cValue.estimated_fps
        self.frameCounter = cValue.frame_counter
        self.lastUpdateTimeNs = cValue.last_update_time_ns
    }
}

internal extension FrameInfo {
    init(_ cValue: CNozzle.NozzleFrameInfo) {
        self.frameIndex = cValue.frame_index
        self.timestampNs = cValue.timestamp_ns
        self.width = cValue.width
        self.height = cValue.height
        self.format = TextureFormat(cValue.format)
        self.semanticFormat = TextureFormat(cValue.semantic_format)
        self.droppedFrameCount = cValue.dropped_frame_count
    }
}
