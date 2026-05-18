import CNozzle

public enum NozzleError: Error, Equatable, CustomStringConvertible {
    case unknown
    case invalidArgument
    case unsupportedBackend
    case unsupportedFormat
    case deviceMismatch
    case resourceCreationFailed
    case sharedHandleFailed
    case senderNotFound
    case senderClosed
    case timeout
    case backendError
    case commandFailed

    public var description: String {
        switch self {
        case .unknown: return "Unknown error"
        case .invalidArgument: return "Invalid argument"
        case .unsupportedBackend: return "Unsupported backend"
        case .unsupportedFormat: return "Unsupported format"
        case .deviceMismatch: return "Device mismatch"
        case .resourceCreationFailed: return "Resource creation failed"
        case .sharedHandleFailed: return "Shared handle operation failed"
        case .senderNotFound: return "Sender not found"
        case .senderClosed: return "Sender closed"
        case .timeout: return "Timeout"
        case .backendError: return "Backend error"
        case .commandFailed: return "Command execution failed"
        }
    }

    init(rawValue: Int) {
        switch rawValue {
        case 1:  self = .unknown
        case 2:  self = .invalidArgument
        case 3:  self = .unsupportedBackend
        case 4:  self = .unsupportedFormat
        case 5:  self = .deviceMismatch
        case 6:  self = .resourceCreationFailed
        case 7:  self = .sharedHandleFailed
        case 8:  self = .senderNotFound
        case 9:  self = .senderClosed
        case 10: self = .timeout
        case 11: self = .backendError
        case 12: self = .commandFailed
        default: self = .unknown
        }
    }
}

internal func check(_ code: CNozzle.NozzleErrorCode) throws {
    guard code.rawValue == 0 else {
        throw NozzleError(rawValue: Int(code.rawValue))
    }
}
