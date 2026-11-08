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

Mapped storage can differ from the requested format: on Metal an RGBA8 request
can map as BGRA8. Inspect `pixels.format` **before** selecting channel offsets,
element type, or bytes per pixel, and use `pixels.rowBytes` for row addresses.
Do not assume byte 0 is red just because `.rgba8Unorm` was requested.

```swift
import Nozzle

// Create a sender
let sender = try Sender.create(name: "my-output", applicationName: "MyApp")

// Acquire a writable frame, draw into it, commit
let frame = try sender.acquireWritableFrame(width: 1920, height: 1080, format: .rgba8Unorm)

// Access pixel data directly
let pixels = try frame.lockWritablePixels()
// Select layout from pixels.format, not the acquisition's requested format.
let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: pixels.byteCount)
// ... write supported mapped pixel data using pixels.rowBytes ...
pixels.unlock()

// Commit the frame for receivers
try sender.commitFrame(frame)
```

### Receiver

The same rule applies on receive: `pixels.format` describes the mapped bytes;
frame/request metadata is not a substitute. Decode only layouts your code
handles, and unlock without reading unsupported layouts.

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
// Inspect pixels.format before interpreting the raw bytes.
let buffer = pixels.data.bindMemory(to: UInt8.self, capacity: pixels.byteCount)
// ... read pixel data ...
pixels.unlock()
```

### Metadata Snapshots

`sender.info` returns owned metadata. `receiver.connectionSnapshot` returns an
optional `ConnectionSnapshot` containing `connected` and `info`, copied together
under the native receiver lock. Imported inline C char tuples are decoded within
their bounds into owned Swift strings; invalid UTF-8 uses replacement characters.
The results remain valid after later calls or handle deinitialization.

Connection state is last-observed, not fresh liveness or a reconnect attempt.
After acquisition observes a disconnect, `connected` is false and `info` retains
last-known sender identity. `connectedInfo` preserves its existing fields and
optional error behavior by projecting the snapshot's info; a non-nil value alone
does not imply a connection. `isConnected` reads the flag, or returns false on
snapshot error. `sender.info` retains its empty/unknown fallback on native error.
This adds no `Sendable` conformance or general thread-safety guarantee.

Real macOS Metal tests cover same-process destruction and retained identity.
Separate imported-struct fixtures test tuple decoding, all mapped metadata,
fractional FPS, and wide counters; these are not native wide-value, pixel, or
cross-process evidence.

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
| `sender.discardFrame(_ frame:)` | Return an unused writable frame's reserved slot without publishing |
| `sender.publishGLTexture(name:target:width:height:format:)` | Publish an OpenGL texture |

### `Receiver`

| Method | Description |
|--------|-------------|
| `Receiver.create(name:applicationName:receiveMode:)` | Create a receiver |
| `Receiver.create(_ desc:)` | Create from descriptor |
| `receiver.acquireFrame(timeoutMs:)` | Acquire the latest frame |
| `receiver.isConnected` | Last-observed connection flag, false on retrieval error |
| `receiver.connectedInfo` | Owned last-known sender details, nil on retrieval error |
| `receiver.connectionSnapshot` | Owned coherent state and metadata, nil on retrieval error |

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
| `format` | Actual mapped storage format; may differ from the requested format |
| `byteCount` | Total buffer size |

### Enums

- **`TextureFormat`** — all 23 current nozzle formats: `r8Unorm`, `rg8Unorm`, `rgb8Unorm`, `rgba8Unorm`, `bgra8Unorm`, `rgba8Srgb`, `bgra8Srgb`, `r16Unorm`, `rg16Unorm`, `rgb16Unorm`, `rgba16Unorm`, `r16Float`, `rg16Float`, `rgb16Float`, `rgba16Float`, `r32Float`, `rg32Float`, `rgb32Float`, `rgba32Float`, `r32Uint`, `rgba32Uint`, `rgb32Uint`, `depth32Float` (plus `unknown`)
- **`BackendType`** — `unknown`, `d3d11`, `metal`, `opengl`, `dmaBuf`
- **`ReceiveMode`** — `latestOnly`, `sequentialBestEffort`

These mappings use imported C constants, not duplicated integer ordinals.
Representing a format/backend does not mean it is available on every platform;
the package remains macOS-only. Unknown future C values map to `unknown`.

### Enum compatibility correction

The previous texture table was offset from core: for example, `.rgba8Unorm`
sent `RGB8_UNORM` and native `BGRA8_UNORM` was read as `.rgba8Srgb`. The corrected
mapping changes those erroneous runtime requests and labels. Remove any client
workaround that intentionally selected the wrong Swift case to compensate.

Existing case names remain, but adding the five RGB formats and `dmaBuf` can
break exhaustive switches in source-based SwiftPM clients. Handle the new cases
when updating; do not rely on Swift enum memory layout or ordinal values for
persistence. This is a behavioral correction with possible source migration,
not a guarantee of binary ABI compatibility. Core's C ABI and values are unchanged.

`EnumContractTests` checks every represented texture/backend against the imported
C constants in both directions, plus receive-mode output and unknown fallback.
The old round-trip tests alone could not catch a table wrong in both directions.
`FrameStatus` currently has no C conversion or use in the wrapper; this correction
does not add an unused bridge for it. Enum checks are not all-format GPU tests.

## Architecture

`SenderExample` and `ReceiverExample` share an internal package target,
`ExamplePixels`, with the example regression tests. It is not part of the
`Nozzle` library product. These examples handle only `rgba8Unorm` and
`bgra8Unorm`; they reject other layouts instead of treating floats, integers,
or sRGB values as linear 8-bit RGBA. This is an example limitation, not removal
of other texture formats from the wrapper.

The tests compare the actual example functions with independent C API readers
and writers on Metal, plus padded CPU fixtures for RGBA/BGRA and unsupported
layouts. The native checks are in-process interoperability tests, not a
cross-process or window-rendering smoke test.

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
- Unlock a writable mapping before committing or discarding its frame.
  Releasing the frame wrapper alone does not return a reserved sender slot.
  The sender example calls `discardFrame` when it rejects a mapped layout.

## License

MIT

Third-party dependencies:

- [nozzle](https://github.com/nozzle-io/nozzle) — MIT
