import CNozzle

public enum BackendType: Equatable {
    case unknown
    case d3d11
    case metal
    case opengl

    init(_ cValue: CNozzle.NozzleBackendType) {
        switch cValue.rawValue {
        case 2: self = .metal
        case 1: self = .d3d11
        case 3: self = .opengl
        default: self = .unknown
        }
    }

    var cValue: CNozzle.NozzleBackendType {
        switch self {
        case .unknown: return .init(rawValue: 0)
        case .d3d11:   return .init(rawValue: 1)
        case .metal:   return .init(rawValue: 2)
        case .opengl:  return .init(rawValue: 3)
        }
    }
}

public enum TextureFormat: Equatable {
    case unknown
    case r8Unorm
    case rg8Unorm
    case rgba8Unorm
    case bgra8Unorm
    case rgba8Srgb
    case bgra8Srgb
    case r16Unorm
    case rg16Unorm
    case rgba16Unorm
    case r16Float
    case rg16Float
    case rgba16Float
    case r32Float
    case rg32Float
    case rgba32Float
    case r32Uint
    case rgba32Uint
    case depth32Float

    init(_ cValue: CNozzle.NozzleTextureFormat) {
        switch cValue.rawValue {
        case 1:  self = .r8Unorm
        case 2:  self = .rg8Unorm
        case 3:  self = .rgba8Unorm
        case 4:  self = .bgra8Unorm
        case 5:  self = .rgba8Srgb
        case 6:  self = .bgra8Srgb
        case 7:  self = .r16Unorm
        case 8:  self = .rg16Unorm
        case 9:  self = .rgba16Unorm
        case 10: self = .r16Float
        case 11: self = .rg16Float
        case 12: self = .rgba16Float
        case 13: self = .r32Float
        case 14: self = .rg32Float
        case 15: self = .rgba32Float
        case 16: self = .r32Uint
        case 17: self = .rgba32Uint
        case 18: self = .depth32Float
        default: self = .unknown
        }
    }

    var cValue: CNozzle.NozzleTextureFormat {
        switch self {
        case .unknown:     return .init(rawValue: 0)
        case .r8Unorm:     return .init(rawValue: 1)
        case .rg8Unorm:    return .init(rawValue: 2)
        case .rgba8Unorm:  return .init(rawValue: 3)
        case .bgra8Unorm:  return .init(rawValue: 4)
        case .rgba8Srgb:   return .init(rawValue: 5)
        case .bgra8Srgb:   return .init(rawValue: 6)
        case .r16Unorm:    return .init(rawValue: 7)
        case .rg16Unorm:   return .init(rawValue: 8)
        case .rgba16Unorm: return .init(rawValue: 9)
        case .r16Float:    return .init(rawValue: 10)
        case .rg16Float:   return .init(rawValue: 11)
        case .rgba16Float: return .init(rawValue: 12)
        case .r32Float:    return .init(rawValue: 13)
        case .rg32Float:   return .init(rawValue: 14)
        case .rgba32Float: return .init(rawValue: 15)
        case .r32Uint:     return .init(rawValue: 16)
        case .rgba32Uint:  return .init(rawValue: 17)
        case .depth32Float: return .init(rawValue: 18)
        }
    }
}

public enum ReceiveMode: Equatable {
    case latestOnly
    case sequentialBestEffort

    var cValue: CNozzle.NozzleReceiveMode {
        switch self {
        case .latestOnly:           return .init(rawValue: 0)
        case .sequentialBestEffort: return .init(rawValue: 1)
        }
    }
}

public enum FrameStatus: Equatable {
    case newFrame
    case noNewFrame
    case droppedFrames
    case senderClosed
    case error
}
