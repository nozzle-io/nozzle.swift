import CNozzle
import XCTest
@testable import Nozzle

final class EnumContractTests: XCTestCase {
    func testTextureFormatsMatchImportedCConstants() {
        let cases: [(TextureFormat, NozzleTextureFormat)] = [
            (.unknown, NOZZLE_FORMAT_UNKNOWN),
            (.r8Unorm, NOZZLE_FORMAT_R8_UNORM),
            (.rg8Unorm, NOZZLE_FORMAT_RG8_UNORM),
            (.rgb8Unorm, NOZZLE_FORMAT_RGB8_UNORM),
            (.rgba8Unorm, NOZZLE_FORMAT_RGBA8_UNORM),
            (.bgra8Unorm, NOZZLE_FORMAT_BGRA8_UNORM),
            (.rgba8Srgb, NOZZLE_FORMAT_RGBA8_SRGB),
            (.bgra8Srgb, NOZZLE_FORMAT_BGRA8_SRGB),
            (.r16Unorm, NOZZLE_FORMAT_R16_UNORM),
            (.rg16Unorm, NOZZLE_FORMAT_RG16_UNORM),
            (.rgb16Unorm, NOZZLE_FORMAT_RGB16_UNORM),
            (.rgba16Unorm, NOZZLE_FORMAT_RGBA16_UNORM),
            (.r16Float, NOZZLE_FORMAT_R16_FLOAT),
            (.rg16Float, NOZZLE_FORMAT_RG16_FLOAT),
            (.rgb16Float, NOZZLE_FORMAT_RGB16_FLOAT),
            (.rgba16Float, NOZZLE_FORMAT_RGBA16_FLOAT),
            (.r32Float, NOZZLE_FORMAT_R32_FLOAT),
            (.rg32Float, NOZZLE_FORMAT_RG32_FLOAT),
            (.rgb32Float, NOZZLE_FORMAT_RGB32_FLOAT),
            (.rgba32Float, NOZZLE_FORMAT_RGBA32_FLOAT),
            (.r32Uint, NOZZLE_FORMAT_R32_UINT),
            (.rgba32Uint, NOZZLE_FORMAT_RGBA32_UINT),
            (.rgb32Uint, NOZZLE_FORMAT_RGB32_UINT),
            (.depth32Float, NOZZLE_FORMAT_DEPTH32_FLOAT),
        ]
        for (swift, native) in cases {
            XCTAssertEqual(swift.cValue, native, "Swift -> C: \(swift)")
            XCTAssertEqual(TextureFormat(native), swift, "C -> Swift: \(swift)")
        }
    }

    func testBackendsMatchImportedCConstants() {
        let cases: [(BackendType, NozzleBackendType)] = [
            (.unknown, NOZZLE_BACKEND_UNKNOWN),
            (.d3d11, NOZZLE_BACKEND_D3D11),
            (.metal, NOZZLE_BACKEND_METAL),
            (.opengl, NOZZLE_BACKEND_OPENGL),
            (.dmaBuf, NOZZLE_BACKEND_DMA_BUF),
        ]
        for (swift, native) in cases {
            XCTAssertEqual(swift.cValue, native, "Swift -> C: \(swift)")
            XCTAssertEqual(BackendType(native), swift, "C -> Swift: \(swift)")
        }
    }

    func testReceiveModesMatchImportedCConstants() {
        XCTAssertEqual(ReceiveMode.latestOnly.cValue, NOZZLE_RECEIVE_LATEST_ONLY)
        XCTAssertEqual(ReceiveMode.sequentialBestEffort.cValue, NOZZLE_RECEIVE_SEQUENTIAL_BEST_EFFORT)
    }

    func testUnrecognizedNativeValuesStayUnknown() {
        XCTAssertEqual(TextureFormat(NozzleTextureFormat(rawValue: UInt32.max)), .unknown)
        XCTAssertEqual(BackendType(NozzleBackendType(rawValue: UInt32.max)), .unknown)
    }
}
