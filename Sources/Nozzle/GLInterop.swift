import CNozzle

public enum GLTarget: UInt32 {
    case texture2D = 0x0DE1
    case textureRectangle = 0x84F5
    case textureExternalOES = 0x8D65
}

extension Sender {
    public func publishGLTexture(name: UInt32, target: GLTarget = .texture2D, width: UInt32, height: UInt32, format: TextureFormat) throws {
        try check(nozzle_sender_publish_gl_texture(ptr, name, target.rawValue, width, height, format.cValue))
    }
}

extension Frame {
    public func copyToGLTexture(name: UInt32, target: GLTarget = .texture2D, width: UInt32, height: UInt32, format: TextureFormat) throws {
        try check(nozzle_frame_copy_to_gl_texture(ptr, name, target.rawValue, width, height, format.cValue))
    }
}
