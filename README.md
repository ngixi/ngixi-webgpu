# ngixi-webgpu

> **🚧 ACTIVE WIP 🚧**  
> *Zig bindings for Google Dawn WebGPU. Works on Windows. Linux/macOS support planned.*

## What This Is

Zig wrapper around Google's Dawn WebGPU implementation for cross-platform GPU rendering.

**Status**: 🔥 Active development, Windows-focused while expanding to other platforms

## What Actually Works

- ✅ Windows Dawn DLL integration
- ✅ Basic WebGPU Zig API  
- ✅ zigwin32 bindings for Windows-specific code
- ✅ DLL fetching from ngixi-builds

## What's Planned/TBD

- 📋 SDL3 components for cross-platform windowing (migrating from Zephyr)
- 📋 Linux Dawn builds
- 📋 macOS Dawn builds (need Mac build infrastructure)
- 📋 More complete WebGPU API coverage

## Quick Start

```bash
zig build        # Build the project
zig build run    # Run test application
```

**Requirements**: Just Zig 0.15.1+ (build system fetches Dawn DLLs automatically)

## Using as a Dependency

Add to `build.zig.zon`:

```zig
.dependencies = .{
    .webgpu = .{
        .url = "https://github.com/ngixi/ngixi-webgpu/archive/<commit>.tar.gz",
    },
},
```

See source code for integration examples. API is minimal and evolving.

## Architecture

- Fetches prebuilt Dawn DLLs from ngixi-builds
- Provides thin Zig wrapper around WebGPU C API
- Windows-first, cross-platform intent

## Status

**Current**: Basic Windows WebGPU instance creation works  
**TBD**: Most everything else—API coverage, platform support, windowing integration

Part of the [NGIXI](https://github.com/ngixi) experimental multimedia framework ecosystem.

---

**Note**: This is research/prototype code. Expect breaking changes and rapid iteration.