# Nozzle.swift

> This codebase is currently in its AI-slob prototyping phase: the code runs on momentum, vibes, and plausible intent.
> Proper debugging will be introduced once demand graduates from hypothetical to measurable.

Idiomatic Swift wrapper for [nozzle](https://github.com/nozzle-io/nozzle) — a cross-platform C/C++17 static library for local inter-process GPU texture sharing.

## Disclaimer / Notice

This library is currently a work in progress and contains many incomplete features and unverified implementations.
Although it may appear usable at first glance, it may not function correctly.

Please use it with the understanding that no guarantees are made regarding its behavior, and perform debugging, validation, and review as needed.
If you encounter problems, please do not become angry; instead, contributions in the form of Issues or Pull Requests would be greatly appreciated.

## Requirements

- macOS 12+
- Swift 5.9+
- Xcode 15+ (or Swift Toolchain)
- CMake 3.20+

## Setup

nozzle is included as a git submodule. Before building, run the bootstrap script:

```bash
git clone git@github.com:nozzle-io/nozzle.swift.git
cd nozzle.swift
git submodule update --init --recursive
./Scripts/bootstrap.sh
```

This initializes the nozzle submodule and builds the static library (`libnozzle.a`).

## Build

```bash
swift build
```

## Test

```bash
swift test
```

## Usage

### Sender

```swift
import Nozzle

// Create a sender
let sender = try Sender.create(name: "my-output", applicationName: "MyApp")

// Acquire a writable frame, draw into it, commit
let frame = try sender.acquireWritableFrame(width: 1920, height: 1080, format: .rgba8Unorm)

// Access pixel data directly
let pixels = try frame.lockWritablePixels()
let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: pixels.byteCount)
// ... write pixel data ...
pixels.unlock()

// Commit the frame for receivers
try sender.commitFrame(frame)
```

### Receiver

```swift
import Nozzle

// Create a receiver that connects to a named sender
let receiver = try Receiver.create(name: "my-output", applicationName: "MyViewer")

// Check connection status
if receiver.isConnected, let info = receiver.connectedInfo {
    print("Connected to \(info.name): \(info.width)x\(info.height) @ \(info.estimatedFps) FPS")
}

// Acquire a frame (blocking until available)
let frame = try receiver.acquireFrame()
let info = frame.info
print("Frame \(info.frameIndex): \(info.width)x\(info.height)")

// Read pixel data
let pixels = try frame.lockPixels()
let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: pixels.byteCount)
// ... read pixel data ...
pixels.unlock()
```

### Discovery

```swift
import Nozzle

// List all available senders on the system
let senders = try Discovery.enumerateSenders()
for sender in senders {
    print("\(sender.name) (\(sender.applicationName)) — \(sender.backend)")
}
```

### Non-blocking Acquire

```swift
let receiver = try Receiver.create(name: "my-output", applicationName: "MyViewer")

// Non-blocking acquire (returns immediately if no new frame)
let frame = try receiver.acquireFrame(timeoutMs: 0)
```

### OpenGL Interop

```swift
// Publish an existing OpenGL texture
try sender.publishGLTexture(name: glTextureName, target: .texture2D, width: 1920, height: 1080, format: .bgra8Unorm)

// Copy a received frame to an OpenGL texture
try frame.copyToGLTexture(name: glTextureName, target: .texture2D, width: 1920, height: 1080, format: .bgra8Unorm)
```

## API Reference

### `Sender`

| Method | Description |
|--------|-------------|
| `Sender.create(name:applicationName:ringBufferSize:allowFormatFallback:)` | Create a sender |
| `Sender.create(_ desc:)` | Create from descriptor |
| `sender.info` | Get sender metadata |
| `sender.acquireWritableFrame(width:height:format:)` | Acquire a frame for writing |
| `sender.commitFrame(_ frame:)` | Publish a committed frame |
| `sender.publishGLTexture(name:target:width:height:format:)` | Publish an OpenGL texture |

### `Receiver`

| Method | Description |
|--------|-------------|
| `Receiver.create(name:applicationName:receiveMode:)` | Create a receiver |
| `Receiver.create(_ desc:)` | Create from descriptor |
| `receiver.acquireFrame(timeoutMs:)` | Acquire the latest frame |
| `receiver.isConnected` | Check if connected to a sender |
| `receiver.connectedInfo` | Get connected sender details |

### `Frame`

| Method | Description |
|--------|-------------|
| `frame.info` | Get frame metadata |
| `frame.lockPixels()` | Map frame pixels for reading |
| `frame.lockWritablePixels()` | Map frame pixels for writing |
| `frame.release()` | Explicitly release (auto-released on deinit) |

### `MappedPixels`

| Property | Description |
|----------|-------------|
| `data` | Raw pointer to pixel buffer |
| `rowBytes` | Bytes per row |
| `width` | Width in pixels |
| `height` | Height in pixels |
| `format` | Pixel format |
| `byteCount` | Total buffer size |

### Enums

- **`TextureFormat`** — `unknown`, `r8Unorm`, `rgba8Unorm`, `bgra8Unorm`, `r16Float`, `r32Float`, `rgba32Float`, etc.
- **`BackendType`** — `unknown`, `d3d11`, `metal`, `opengl`
- **`ReceiveMode`** — `latestOnly`, `sequentialBestEffort`

## Architecture

```
nozzle.swift (this package)
├── Sources/CNozzle/       C modulemap → deps/nozzle/include/nozzle/nozzle_c.h
├── Sources/Nozzle/        Swift wrapper over C ABI
├── deps/nozzle/           git submodule (C/C++17 static library)
└── Scripts/bootstrap.sh   Builds nozzle static library
```

The Swift wrapper calls exclusively through the C ABI (`nozzle_c.h`). The C++ API is never used directly.

## Memory Management

- `Sender`, `Receiver`, `Frame`, `Device` — reference types with `deinit` that call the corresponding C destroy functions
- `MappedPixels` — auto-unlocks on deinit; explicit `unlock()` available
- `Frame.release()` — safe to call multiple times (no-op after first release)

## License

MIT

Third-party dependencies:

- [nozzle](https://github.com/nozzle-io/nozzle) — MIT
