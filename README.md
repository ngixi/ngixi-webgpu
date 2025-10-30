# NGIXI Dawn WebGPU Zig API

This Zig package provides a minimal Zig API for Google Dawn WebGPU, fetching the native DLL and providing Zig bindings with Win32 integration.

## What this does

- ✅ Fetches the Dawn WebGPU DLL from your ngixi-builds repository
- ✅ Extracts the tarball into `zig-cache`
- ✅ Provides Zig bindings for basic WebGPU operations
- ✅ Links against the DLL at build time
- ✅ Installs the DLL for runtime loading
- ✅ Creates a working "Hello World" test that verifies DLL loading
- ✅ **NEW**: Includes zigwin32 for Windows API access
- ✅ **NEW**: Includes Zephyr for cross-platform windowing
- ✅ **NEW**: Creates an empty window application

## Dependencies

- **Dawn**: WebGPU implementation from Google
- **zigwin32**: Windows API bindings for Zig
- **Zephyr**: Cross-platform windowing library

## Files Created

After `zig build`:

- `zig-out/bin/dawn-test.exe` - Empty window application that loads and uses the DLL
- `zig-out/bin/webgpu_dawn.dll` - The Dawn WebGPU DLL (copied for runtime)
- `zig-out/include/dawn/webgpu.h` - C header file

## Usage

### Build and test

```bash
zig build        # Build the project
zig build run    # Run the empty window application (verifies DLL loading)
```

### Using as a dependency in other projects

Add this to your `build.zig.zon`:

```zig
.dependencies = .{
    .dawn = .{
        .path = "path/to/this/package",
    },
},
```

Then in your `build.zig`:

```zig
const dawn_dep = b.dependency("dawn", .{});
const dawn_module = dawn_dep.module("dawn");
const zigwin32 = b.dependency("zigwin32", .{});

// Add to your executable
exe.root_module.addImport("dawn", dawn_module);
exe.root_module.addImport("win32", zigwin32.module("win32"));
exe.root_module.addImport("zephyr", b.addModule("zephyr", .{
    .root_source_file = b.path("src/zephyr/app.zig"),
}));
exe.root_module.addIncludePath(dawn_dep.path("windows-x64/include"));
exe.root_module.addLibraryPath(dawn_dep.path("windows-x64/lib"));
exe.linkSystemLibrary("webgpu_dawn");
exe.linkLibC();

// Copy the DLL to your output
b.installBinFile(dawn_dep.path("windows-x64/bin/webgpu_dawn.dll"), "webgpu_dawn.dll");
```

### Zig API Usage

```zig
const dawn = @import("dawn");
const win32 = @import("win32");
const zephyr = @import("zephyr/app.zig");
const WindowOptions = @import("zephyr/window.zig").WindowOptions;

// Create a WebGPU instance
const instance = dawn.createInstance(null);
if (instance) |inst| {
    // Use WebGPU...
    dawn.instanceRelease(inst);
}

// Create a window
const window_options = WindowOptions{
    .title = "My WebGPU App",
    .width = 800,
    .height = 600,
};

const exit_code = try zephyr.runSingleWindow(std.heap.page_allocator, window_options, null);
```

## Current API

The `src/dawn.zig` file provides:

- `createInstance()` - Create WebGPU instance
- `instanceRelease()` - Release instance
- Basic type definitions for WebGPU objects
- External function declarations for the DLL

## Status

✅ **WORKING**: DLL loads successfully, basic WebGPU instance creation works, Win32 APIs available, empty window application runs.

This is a minimal implementation focused on getting the DLL loading and basic API working. More WebGPU functions can be added to `dawn.zig` as needed.
