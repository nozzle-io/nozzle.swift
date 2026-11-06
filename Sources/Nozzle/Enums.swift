import CNozzle

public enum BackendType: Equatable {
    case unknown
    case d3d11
    case metal
    case opengl
    case dmaBuf

    init(_ cValue: CNozzle.NozzleBackendType) {
        switch cValue {
        case NOZZLE_BACKEND_METAL: self = .metal
        case NOZZLE_BACKEND_D3D11: self = .d3d11
        case NOZZLE_BACKEND_OPENGL: self = .opengl
        case NOZZLE_BACKEND_DMA_BUF: self = .dmaBuf
        default: self = .unknown
        }
    }

    var cValue: CNozzle.NozzleBackendType {
        switch self {
        case .unknown: return NOZZLE_BACKEND_UNKNOWN
        case .d3d11:   return NOZZLE_BACKEND_D3D11
        case .metal:   return NOZZLE_BACKEND_METAL
        case .opengl:  return NOZZLE_BACKEND_OPENGL
        case .dmaBuf:  return NOZZLE_BACKEND_DMA_BUF
        }
    }
}

public enum TextureFormat: Equatable {
    case unknown
    case r8Unorm
    case rg8Unorm
    case rgb8Unorm
    case rgba8Unorm
    case bgra8Unorm
    case rgba8Srgb
    case bgra8Srgb
    case r16Unorm
    case rg16Unorm
    case rgb16Unorm
    case rgba16Unorm
    case r16Float
    case rg16Float
    case rgb16Float
    case rgba16Float
    case r32Float
    case rg32Float
    case rgb32Float
    case rgba32Float
    case r32Uint
    case rgba32Uint
    case rgb32Uint
    case depth32Float

    init(_ cValue: CNozzle.NozzleTextureFormat) {
        switch cValue {
        case NOZZLE_FORMAT_R8_UNORM: self = .r8Unorm
        case NOZZLE_FORMAT_RG8_UNORM: self = .rg8Unorm
        case NOZZLE_FORMAT_RGB8_UNORM: self = .rgb8Unorm
        case NOZZLE_FORMAT_RGBA8_UNORM: self = .rgba8Unorm
        case NOZZLE_FORMAT_BGRA8_UNORM: self = .bgra8Unorm
        case NOZZLE_FORMAT_RGBA8_SRGB: self = .rgba8Srgb
        case NOZZLE_FORMAT_BGRA8_SRGB: self = .bgra8Srgb
        case NOZZLE_FORMAT_R16_UNORM: self = .r16Unorm
        case NOZZLE_FORMAT_RG16_UNORM: self = .rg16Unorm
        case NOZZLE_FORMAT_RGB16_UNORM: self = .rgb16Unorm
        case NOZZLE_FORMAT_RGBA16_UNORM: self = .rgba16Unorm
        case NOZZLE_FORMAT_R16_FLOAT: self = .r16Float
        case NOZZLE_FORMAT_RG16_FLOAT: self = .rg16Float
        case NOZZLE_FORMAT_RGB16_FLOAT: self = .rgb16Float
        case NOZZLE_FORMAT_RGBA16_FLOAT: self = .rgba16Float
        case NOZZLE_FORMAT_R32_FLOAT: self = .r32Float
        case NOZZLE_FORMAT_RG32_FLOAT: self = .rg32Float
        case NOZZLE_FORMAT_RGB32_FLOAT: self = .rgb32Float
        case NOZZLE_FORMAT_RGBA32_FLOAT: self = .rgba32Float
        case NOZZLE_FORMAT_R32_UINT: self = .r32Uint
        case NOZZLE_FORMAT_RGBA32_UINT: self = .rgba32Uint
        case NOZZLE_FORMAT_RGB32_UINT: self = .rgb32Uint
        case NOZZLE_FORMAT_DEPTH32_FLOAT: self = .depth32Float
        default: self = .unknown
        }
    }

    var cValue: CNozzle.NozzleTextureFormat {
        switch self {
        case .unknown:     return NOZZLE_FORMAT_UNKNOWN
        case .r8Unorm:     return NOZZLE_FORMAT_R8_UNORM
        case .rg8Unorm:    return NOZZLE_FORMAT_RG8_UNORM
        case .rgb8Unorm:   return NOZZLE_FORMAT_RGB8_UNORM
        case .rgba8Unorm:  return NOZZLE_FORMAT_RGBA8_UNORM
        case .bgra8Unorm:  return NOZZLE_FORMAT_BGRA8_UNORM
        case .rgba8Srgb:   return NOZZLE_FORMAT_RGBA8_SRGB
        case .bgra8Srgb:   return NOZZLE_FORMAT_BGRA8_SRGB
        case .r16Unorm:    return NOZZLE_FORMAT_R16_UNORM
        case .rg16Unorm:   return NOZZLE_FORMAT_RG16_UNORM
        case .rgb16Unorm:  return NOZZLE_FORMAT_RGB16_UNORM
        case .rgba16Unorm: return NOZZLE_FORMAT_RGBA16_UNORM
        case .r16Float:    return NOZZLE_FORMAT_R16_FLOAT
        case .rg16Float:   return NOZZLE_FORMAT_RG16_FLOAT
        case .rgb16Float:  return NOZZLE_FORMAT_RGB16_FLOAT
        case .rgba16Float: return NOZZLE_FORMAT_RGBA16_FLOAT
        case .r32Float:    return NOZZLE_FORMAT_R32_FLOAT
        case .rg32Float:   return NOZZLE_FORMAT_RG32_FLOAT
        case .rgb32Float:  return NOZZLE_FORMAT_RGB32_FLOAT
        case .rgba32Float: return NOZZLE_FORMAT_RGBA32_FLOAT
        case .r32Uint:     return NOZZLE_FORMAT_R32_UINT
        case .rgba32Uint:  return NOZZLE_FORMAT_RGBA32_UINT
        case .rgb32Uint:   return NOZZLE_FORMAT_RGB32_UINT
        case .depth32Float: return NOZZLE_FORMAT_DEPTH32_FLOAT
        }
    }
}

public enum ReceiveMode: Equatable {
    case latestOnly
    case sequentialBestEffort

    var cValue: CNozzle.NozzleReceiveMode {
        switch self {
        case .latestOnly:          return NOZZLE_RECEIVE_LATEST_ONLY
        case .sequentialBestEffort: return NOZZLE_RECEIVE_SEQUENTIAL_BEST_EFFORT
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
