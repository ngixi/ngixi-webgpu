# Dawn WebGPU Zig Wrapper - Architectural Plan

## Core Philosophy

### Files as Structs Pattern

Zig allows files to be treated as structs when they have root-level fields and an `init` function. This eliminates redundant wrapping and provides a clean, idiomatic API.

**Example:**

```zig
// instance.zig - The file itself IS the Instance struct
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUInstance,

pub fn init(desc: ?InstanceDescriptor) !@This() {
    const handle = raw.wgpuCreateInstance(if (desc) |d| &d.toRaw() else null);
    return .{ .handle = handle orelse return error.InstanceCreateFailed };
}

pub fn deinit(self: @This()) void {
    raw.wgpuInstanceRelease(self.handle);
}

pub fn requestAdapter(self: @This(), options: AdapterOptions) !Adapter {
    // Implementation
}
```

**Usage:**

```zig
const Instance = @import("core/instance.zig");
const instance = try Instance.init(null);
defer instance.deinit();
```

### Design Principles

1. **Files as Structs** - No redundant struct declarations
2. **Explicit Lifetime** - Always `init()` and `deinit()`, no RAII magic
3. **Error Unions** - No callbacks, convert async to sync with errors
4. **Type Safety** - Zig enums/unions, not raw C types
5. **Zero Cost** - Direct calls to C, no overhead
6. **Builder Patterns** - For complex descriptors
7. **Comptime Where Possible** - Validate at compile time

---

## Project Structure

```
src/dawn/
├── dawn.zig                    # Main public API (re-exports everything)
├── raw/
│   └── c.zig                   # @cImport("webgpu.h") ✓ DONE
│
├── core/                       # Core WebGPU objects (files as structs)
│   ├── instance.zig            # Instance type (file is the struct)
│   ├── adapter.zig             # Adapter type (file is the struct)
│   ├── device.zig              # Device type (file is the struct)
│   ├── queue.zig               # Queue type (file is the struct)
│   └── surface.zig             # Surface type (file is the struct)
│
├── resources/                  # GPU resources (files as structs)
│   ├── buffer.zig              # Buffer type (file is the struct)
│   ├── texture.zig             # Texture type (file is the struct)
│   ├── texture_view.zig        # TextureView type (file is the struct)
│   └── sampler.zig             # Sampler type (file is the struct)
│
├── pipeline/                   # Pipeline objects (files as structs)
│   ├── shader_module.zig       # ShaderModule type (file is the struct)
│   ├── render_pipeline.zig     # RenderPipeline type (file is the struct)
│   ├── pipeline_layout.zig     # PipelineLayout type (file is the struct)
│   ├── bind_group.zig          # BindGroup type (file is the struct)
│   └── bind_group_layout.zig   # BindGroupLayout type (file is the struct)
│
├── commands/                   # Command recording (files as structs)
│   ├── command_encoder.zig     # CommandEncoder type (file is the struct)
│   ├── command_buffer.zig      # CommandBuffer type (file is the struct)
│   └── render_pass.zig         # RenderPassEncoder type (file is the struct)
│
├── types/                      # Shared types (NOT files as structs, pure data)
│   ├── enums.zig               # Zig enums mirroring WebGPU enums
│   ├── structs.zig             # Common structs (Color, Extent3D, etc)
│   └── descriptors.zig         # Descriptor types with .toRaw() methods
│
└── utils/
    ├── sync.zig                # Async→Sync helpers (callbacks to errors)
    └── platform.zig            # Platform-specific surface creation
```

---

## Phase 1: Foundation & Minimal Triangle

**Goal:** Render a solid colored triangle in a window

### Step 1.1: Type System (Week 1, Day 1-2)

**File:** `src/dawn/types/enums.zig`

```zig
// Zig-idiomatic enums that map to WebGPU enums
pub const TextureFormat = enum(u32) {
    bgra8_unorm = 0x00000001,
    rgba8_unorm = 0x00000002,
    // ... etc

    pub fn toRaw(self: TextureFormat) c_uint {
        return @intFromEnum(self);
    }
};

pub const PresentMode = enum(u32) {
    immediate = 0x00000001,
    mailbox = 0x00000002,
    fifo = 0x00000003,

    pub fn toRaw(self: PresentMode) c_uint {
        return @intFromEnum(self);
    }
};

pub const LoadOp = enum(u32) {
    undefined = 0x00000000,
    clear = 0x00000001,
    load = 0x00000002,

    pub fn toRaw(self: LoadOp) c_uint {
        return @intFromEnum(self);
    }
};

pub const StoreOp = enum(u32) {
    undefined = 0x00000000,
    store = 0x00000001,
    discard = 0x00000002,

    pub fn toRaw(self: StoreOp) c_uint {
        return @intFromEnum(self);
    }
};
```

**File:** `src/dawn/types/structs.zig`

```zig
const raw = @import("../raw/c.zig").c;

pub const Color = struct {
    r: f64,
    g: f64,
    b: f64,
    a: f64,

    pub fn toRaw(self: Color) raw.WGPUColor {
        return .{ .r = self.r, .g = self.g, .b = self.b, .a = self.a };
    }
};

pub const Extent3D = struct {
    width: u32,
    height: u32 = 1,
    depth_or_array_layers: u32 = 1,

    pub fn toRaw(self: Extent3D) raw.WGPUExtent3D {
        return .{
            .width = self.width,
            .height = self.height,
            .depthOrArrayLayers = self.depth_or_array_layers,
        };
    }
};
```

**File:** `src/dawn/types/descriptors.zig`

```zig
const raw = @import("../raw/c.zig").c;
const enums = @import("enums.zig");
const structs = @import("structs.zig");

pub const SurfaceConfiguration = struct {
    format: enums.TextureFormat,
    width: u32,
    height: u32,
    present_mode: enums.PresentMode = .fifo,
    alpha_mode: enums.CompositeAlphaMode = .opaque,

    pub fn toRaw(self: SurfaceConfiguration, device_handle: raw.WGPUDevice) raw.WGPUSurfaceConfiguration {
        return .{
            .device = device_handle,
            .format = self.format.toRaw(),
            .width = self.width,
            .height = self.height,
            .presentMode = self.present_mode.toRaw(),
            .alphaMode = self.alpha_mode.toRaw(),
            // ... other fields with defaults
        };
    }
};

pub const RenderPassColorAttachment = struct {
    view: raw.WGPUTextureView,
    load_op: enums.LoadOp,
    store_op: enums.StoreOp,
    clear_value: ?structs.Color = null,

    pub fn toRaw(self: RenderPassColorAttachment) raw.WGPURenderPassColorAttachment {
        return .{
            .view = self.view,
            .loadOp = self.load_op.toRaw(),
            .storeOp = self.store_op.toRaw(),
            .clearValue = if (self.clear_value) |c| c.toRaw() else .{},
            // ...
        };
    }
};
```

### Step 1.2: Core Objects - Instance & Surface (Week 1, Day 3-4)

**File:** `src/dawn/core/instance.zig`

```zig
// This file IS the Instance type - no redundant struct wrapper!
const std = @import("std");
const raw = @import("../raw/c.zig").c;

// Root-level field - this makes the file a struct
handle: raw.WGPUInstance,

// Constructor
pub fn init(desc: ?InstanceDescriptor) !@This() {
    const raw_desc: ?*const raw.WGPUInstanceDescriptor = if (desc) |d| &d.toRaw() else null;
    const handle = raw.wgpuCreateInstance(raw_desc);
    if (handle == null) return error.InstanceCreateFailed;
    return .{ .handle = handle.? };
}

// Destructor
pub fn deinit(self: @This()) void {
    raw.wgpuInstanceRelease(self.handle);
}

// Methods
pub fn createSurface(self: @This(), window_handle: *anyopaque) !Surface {
    const Surface = @import("surface.zig");
    return Surface.initFromHWND(self, window_handle);
}

pub fn requestAdapter(self: @This(), options: AdapterOptions) !Adapter {
    const Adapter = @import("adapter.zig");
    return Adapter.request(self, options);
}

// Private types for this module
const InstanceDescriptor = struct {
    // fields...
    pub fn toRaw(self: @This()) raw.WGPUInstanceDescriptor {
        // ...
    }
};

const AdapterOptions = struct {
    // fields...
};

const Adapter = @import("adapter.zig");
const Surface = @import("surface.zig");
```

**File:** `src/dawn/core/surface.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;
const types = @import("../types/descriptors.zig");

handle: raw.WGPUSurface,

pub fn initFromHWND(instance: Instance, hwnd: *anyopaque) !@This() {
    const descriptor = raw.WGPUSurfaceDescriptor{
        .nextInChain = @ptrCast(&raw.WGPUSurfaceSourceWindowsHWND{
            .chain = .{ .sType = raw.WGPUSType_SurfaceSourceWindowsHWND },
            .hwnd = hwnd,
            .hinstance = null,
        }),
    };

    const handle = raw.wgpuInstanceCreateSurface(instance.handle, &descriptor);
    if (handle == null) return error.SurfaceCreateFailed;
    return .{ .handle = handle.? };
}

pub fn deinit(self: @This()) void {
    raw.wgpuSurfaceRelease(self.handle);
}

pub fn configure(self: @This(), device: Device, config: types.SurfaceConfiguration) void {
    const raw_config = config.toRaw(device.handle);
    raw.wgpuSurfaceConfigure(self.handle, &raw_config);
}

pub fn getCurrentTexture(self: @This()) !SurfaceTexture {
    var surface_texture: raw.WGPUSurfaceTexture = undefined;
    raw.wgpuSurfaceGetCurrentTexture(self.handle, &surface_texture);

    if (surface_texture.status != raw.WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal) {
        return error.SurfaceTextureAcquireFailed;
    }

    return .{ .texture = surface_texture.texture };
}

pub fn present(self: @This()) void {
    raw.wgpuSurfacePresent(self.handle);
}

const Instance = @import("instance.zig");
const Device = @import("device.zig");

pub const SurfaceTexture = struct {
    texture: raw.WGPUTexture,
};
```

### Step 1.3: Device & Adapter (Week 1, Day 5-7)

**File:** `src/dawn/core/adapter.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;
const sync = @import("../utils/sync.zig");

handle: raw.WGPUAdapter,

pub fn request(instance: Instance, options: RequestOptions) !@This() {
    // Use sync helper to convert async callback to sync error
    const result = try sync.requestAdapterSync(instance.handle, options);
    return .{ .handle = result };
}

pub fn deinit(self: @This()) void {
    raw.wgpuAdapterRelease(self.handle);
}

pub fn requestDevice(self: @This(), desc: ?DeviceDescriptor) !Device {
    const Device = @import("device.zig");
    const result = try sync.requestDeviceSync(self.handle, desc);
    return Device{ .handle = result };
}

const Instance = @import("instance.zig");
const Device = @import("device.zig");

pub const RequestOptions = struct {
    compatible_surface: ?Surface = null,
    power_preference: PowerPreference = .high_performance,

    pub fn toRaw(self: @This()) raw.WGPURequestAdapterOptions {
        // ...
    }
};

pub const DeviceDescriptor = struct {
    // fields...
};

pub const PowerPreference = enum(u32) {
    undefined = 0,
    low_power = 1,
    high_performance = 2,
};

const Surface = @import("surface.zig");
```

**File:** `src/dawn/core/device.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUDevice,

pub fn getQueue(self: @This()) Queue {
    const Queue = @import("queue.zig");
    const handle = raw.wgpuDeviceGetQueue(self.handle);
    return Queue{ .handle = handle };
}

pub fn deinit(self: @This()) void {
    raw.wgpuDeviceRelease(self.handle);
}

pub fn createShaderModule(self: @This(), source: ShaderSource) !ShaderModule {
    const ShaderModule = @import("../pipeline/shader_module.zig");
    return ShaderModule.init(self, source);
}

pub fn createRenderPipeline(self: @This(), desc: RenderPipelineDescriptor) !RenderPipeline {
    const RenderPipeline = @import("../pipeline/render_pipeline.zig");
    return RenderPipeline.init(self, desc);
}

pub fn createCommandEncoder(self: @This()) !CommandEncoder {
    const CommandEncoder = @import("../commands/command_encoder.zig");
    return CommandEncoder.init(self);
}

pub fn createBuffer(self: @This(), desc: BufferDescriptor) !Buffer {
    const Buffer = @import("../resources/buffer.zig");
    return Buffer.init(self, desc);
}

const Queue = @import("queue.zig");
const ShaderModule = @import("../pipeline/shader_module.zig");
const RenderPipeline = @import("../pipeline/render_pipeline.zig");
const CommandEncoder = @import("../commands/command_encoder.zig");
const Buffer = @import("../resources/buffer.zig");

pub const ShaderSource = union(enum) {
    wgsl: []const u8,
    spirv: []const u32,
};

pub const RenderPipelineDescriptor = struct {
    // fields...
};

pub const BufferDescriptor = struct {
    // fields...
};
```

**File:** `src/dawn/core/queue.zig`

```zig
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUQueue,

pub fn submit(self: @This(), command_buffers: []const CommandBuffer) void {
    var raw_buffers = std.ArrayList(raw.WGPUCommandBuffer).init(allocator);
    defer raw_buffers.deinit();

    for (command_buffers) |cb| {
        raw_buffers.append(cb.handle) catch unreachable;
    }

    raw.wgpuQueueSubmit(self.handle, @intCast(raw_buffers.items.len), raw_buffers.items.ptr);
}

pub fn writeBuffer(self: @This(), buffer: Buffer, offset: u64, data: []const u8) void {
    raw.wgpuQueueWriteBuffer(self.handle, buffer.handle, offset, data.ptr, data.len);
}

pub fn deinit(self: @This()) void {
    raw.wgpuQueueRelease(self.handle);
}

const CommandBuffer = @import("../commands/command_buffer.zig");
const Buffer = @import("../resources/buffer.zig");
```

### Step 1.4: Shader & Pipeline (Week 2, Day 1-3)

**File:** `src/dawn/pipeline/shader_module.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUShaderModule,

pub fn init(device: Device, source: ShaderSource) !@This() {
    const descriptor = switch (source) {
        .wgsl => |code| blk: {
            const wgsl_desc = raw.WGPUShaderSourceWGSL{
                .chain = .{ .sType = raw.WGPUSType_ShaderSourceWGSL },
                .code = .{ .data = code.ptr, .length = code.len },
            };
            break :blk raw.WGPUShaderModuleDescriptor{
                .nextInChain = @ptrCast(&wgsl_desc),
            };
        },
        .spirv => |code| blk: {
            // Similar for SPIRV
            break :blk raw.WGPUShaderModuleDescriptor{ /* ... */ };
        },
    };

    const handle = raw.wgpuDeviceCreateShaderModule(device.handle, &descriptor);
    if (handle == null) return error.ShaderModuleCreateFailed;
    return .{ .handle = handle.? };
}

pub fn deinit(self: @This()) void {
    raw.wgpuShaderModuleRelease(self.handle);
}

const Device = @import("../core/device.zig");

pub const ShaderSource = union(enum) {
    wgsl: []const u8,
    spirv: []const u32,
};
```

**File:** `src/dawn/pipeline/render_pipeline.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;
const enums = @import("../types/enums.zig");

handle: raw.WGPURenderPipeline,

pub fn init(device: Device, desc: Descriptor) !@This() {
    const raw_desc = desc.toRaw();
    const handle = raw.wgpuDeviceCreateRenderPipeline(device.handle, &raw_desc);
    if (handle == null) return error.RenderPipelineCreateFailed;
    return .{ .handle = handle.? };
}

pub fn deinit(self: @This()) void {
    raw.wgpuRenderPipelineRelease(self.handle);
}

const Device = @import("../core/device.zig");
const ShaderModule = @import("shader_module.zig");

pub const Descriptor = struct {
    vertex_shader: ShaderModule,
    vertex_entry_point: []const u8 = "vs_main",
    fragment_shader: ?ShaderModule = null,
    fragment_entry_point: []const u8 = "fs_main",
    color_target_format: enums.TextureFormat,
    primitive_topology: enums.PrimitiveTopology = .triangle_list,

    pub fn toRaw(self: @This()) raw.WGPURenderPipelineDescriptor {
        // Build complex descriptor
        return .{
            // ...
        };
    }
};
```

### Step 1.5: Command Recording (Week 2, Day 4-7)

**File:** `src/dawn/commands/command_encoder.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUCommandEncoder,

pub fn init(device: Device) !@This() {
    const handle = raw.wgpuDeviceCreateCommandEncoder(device.handle, null);
    if (handle == null) return error.CommandEncoderCreateFailed;
    return .{ .handle = handle.? };
}

pub fn beginRenderPass(self: *@This(), desc: RenderPassDescriptor) RenderPassEncoder {
    const RenderPassEncoder = @import("render_pass.zig");
    const raw_desc = desc.toRaw();
    const handle = raw.wgpuCommandEncoderBeginRenderPass(self.handle, &raw_desc);
    return RenderPassEncoder{ .handle = handle };
}

pub fn finish(self: @This()) !CommandBuffer {
    const CommandBuffer = @import("command_buffer.zig");
    const handle = raw.wgpuCommandEncoderFinish(self.handle, null);
    if (handle == null) return error.CommandBufferFinishFailed;
    return CommandBuffer{ .handle = handle.? };
}

pub fn deinit(self: @This()) void {
    raw.wgpuCommandEncoderRelease(self.handle);
}

const Device = @import("../core/device.zig");
const RenderPassEncoder = @import("render_pass.zig");
const CommandBuffer = @import("command_buffer.zig");

pub const RenderPassDescriptor = struct {
    // fields...
    pub fn toRaw(self: @This()) raw.WGPURenderPassDescriptor {
        // ...
    }
};
```

**File:** `src/dawn/commands/render_pass.zig`

```zig
const raw = @import("../raw/c.zig").c;

handle: raw.WGPURenderPassEncoder,

pub fn setPipeline(self: *@This(), pipeline: RenderPipeline) void {
    raw.wgpuRenderPassEncoderSetPipeline(self.handle, pipeline.handle);
}

pub fn setVertexBuffer(self: *@This(), slot: u32, buffer: Buffer, offset: u64, size: u64) void {
    raw.wgpuRenderPassEncoderSetVertexBuffer(self.handle, slot, buffer.handle, offset, size);
}

pub fn draw(self: *@This(), vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
    raw.wgpuRenderPassEncoderDraw(self.handle, vertex_count, instance_count, first_vertex, first_instance);
}

pub fn end(self: *@This()) void {
    raw.wgpuRenderPassEncoderEnd(self.handle);
}

// Note: RenderPassEncoder doesn't have explicit release in WebGPU
// It's released when the command encoder is released

const RenderPipeline = @import("../pipeline/render_pipeline.zig");
const Buffer = @import("../resources/buffer.zig");
```

**File:** `src/dawn/commands/command_buffer.zig`

```zig
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUCommandBuffer,

pub fn deinit(self: @This()) void {
    raw.wgpuCommandBufferRelease(self.handle);
}

// CommandBuffer is immutable - no methods after creation
```

### Step 1.6: Resources - Buffer & Texture (Week 3)

**File:** `src/dawn/resources/buffer.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUBuffer,
size: u64,
usage: BufferUsage,

pub fn init(device: Device, desc: Descriptor) !@This() {
    const raw_desc = desc.toRaw();
    const handle = raw.wgpuDeviceCreateBuffer(device.handle, &raw_desc);
    if (handle == null) return error.BufferCreateFailed;

    return .{
        .handle = handle.?,
        .size = desc.size,
        .usage = desc.usage,
    };
}

pub fn deinit(self: @This()) void {
    raw.wgpuBufferRelease(self.handle);
}

const Device = @import("../core/device.zig");

pub const Descriptor = struct {
    size: u64,
    usage: BufferUsage,
    mapped_at_creation: bool = false,

    pub fn toRaw(self: @This()) raw.WGPUBufferDescriptor {
        return .{
            .size = self.size,
            .usage = @bitCast(self.usage),
            .mappedAtCreation = if (self.mapped_at_creation) 1 else 0,
        };
    }
};

pub const BufferUsage = packed struct(u32) {
    map_read: bool = false,
    map_write: bool = false,
    copy_src: bool = false,
    copy_dst: bool = false,
    index: bool = false,
    vertex: bool = false,
    uniform: bool = false,
    storage: bool = false,
    indirect: bool = false,
    query_resolve: bool = false,
    _padding: u22 = 0,
};
```

**File:** `src/dawn/resources/texture_view.zig`

```zig
const raw = @import("../raw/c.zig").c;

handle: raw.WGPUTextureView,

pub fn deinit(self: @This()) void {
    raw.wgpuTextureViewRelease(self.handle);
}
```

### Step 1.7: Utility - Async to Sync Conversion (Week 3)

**File:** `src/dawn/utils/sync.zig`

```zig
const std = @import("std");
const raw = @import("../raw/c.zig").c;

// Thread-local storage for callback results
threadlocal var adapter_result: ?raw.WGPUAdapter = null;
threadlocal var device_result: ?raw.WGPUDevice = null;

pub fn requestAdapterSync(instance: raw.WGPUInstance, options: anytype) !raw.WGPUAdapter {
    adapter_result = null;

    const callback_info = raw.WGPURequestAdapterCallbackInfo{
        .mode = raw.WGPUCallbackMode_AllowSpontaneous,
        .callback = adapterCallback,
        .userdata = null,
    };

    const opts = options.toRaw();
    const future = raw.wgpuInstanceRequestAdapter(instance, &opts, callback_info);

    // Wait for callback (blocking)
    _ = raw.wgpuInstanceWaitAny(instance, 1, &future, std.math.maxInt(u64));

    return adapter_result orelse error.AdapterRequestFailed;
}

fn adapterCallback(
    status: raw.WGPURequestAdapterStatus,
    adapter: raw.WGPUAdapter,
    message: [*c]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void {
    _ = userdata;
    _ = message;

    if (status == raw.WGPURequestAdapterStatus_Success) {
        adapter_result = adapter;
    }
}

pub fn requestDeviceSync(adapter: raw.WGPUAdapter, desc: anytype) !raw.WGPUDevice {
    device_result = null;

    const callback_info = raw.WGPURequestDeviceCallbackInfo{
        .mode = raw.WGPUCallbackMode_AllowSpontaneous,
        .callback = deviceCallback,
        .userdata = null,
    };

    const raw_desc = if (desc) |d| d.toRaw() else null;
    const future = raw.wgpuAdapterRequestDevice(adapter, raw_desc, callback_info);

    // Wait for callback
    _ = raw.wgpuAdapterWaitAny(adapter, 1, &future, std.math.maxInt(u64));

    return device_result orelse error.DeviceRequestFailed;
}

fn deviceCallback(
    status: raw.WGPURequestDeviceStatus,
    device: raw.WGPUDevice,
    message: [*c]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void {
    _ = userdata;
    _ = message;

    if (status == raw.WGPURequestDeviceStatus_Success) {
        device_result = device;
    }
}
```

### Step 1.8: Main Entry Point (Week 4)

**File:** `src/dawn/dawn.zig`

```zig
// Main public API - re-export everything

// Core objects (files as structs)
pub const Instance = @import("core/instance.zig");
pub const Adapter = @import("core/adapter.zig");
pub const Device = @import("core/device.zig");
pub const Queue = @import("core/queue.zig");
pub const Surface = @import("core/surface.zig");

// Resources (files as structs)
pub const Buffer = @import("resources/buffer.zig");
pub const Texture = @import("resources/texture.zig");
pub const TextureView = @import("resources/texture_view.zig");

// Pipeline (files as structs)
pub const ShaderModule = @import("pipeline/shader_module.zig");
pub const RenderPipeline = @import("pipeline/render_pipeline.zig");

// Commands (files as structs)
pub const CommandEncoder = @import("commands/command_encoder.zig");
pub const CommandBuffer = @import("commands/command_buffer.zig");
pub const RenderPassEncoder = @import("commands/render_pass.zig");

// Types
pub const types = struct {
    pub usingnamespace @import("types/enums.zig");
    pub usingnamespace @import("types/structs.zig");
    pub usingnamespace @import("types/descriptors.zig");
};

// Raw C bindings (for advanced users)
pub const raw = @import("raw/c.zig");
```

### Step 1.9: Example Usage (main.zig)

```zig
const std = @import("std");
const dawn = @import("dawn");
const zephyr = @import("zephyr");

pub fn main() !void {
    // Initialize WebGPU
    const instance = try dawn.Instance.init(null);
    defer instance.deinit();

    // Create window
    const window = try zephyr.Window.create(.{
        .title = "Dawn Triangle",
        .width = 800,
        .height = 600,
    });
    defer window.destroy();

    // Create surface
    const surface = try instance.createSurface(window.getNativeHandle());
    defer surface.deinit();

    // Get adapter & device
    const adapter = try instance.requestAdapter(.{ .compatible_surface = surface });
    defer adapter.deinit();

    const device = try adapter.requestDevice(null);
    defer device.deinit();

    const queue = device.getQueue();
    defer queue.deinit();

    // Configure surface
    surface.configure(device, .{
        .format = .bgra8_unorm,
        .width = 800,
        .height = 600,
        .present_mode = .fifo,
    });

    // Create shader
    const shader = try device.createShaderModule(.{ .wgsl =
        \\@vertex fn vs_main(@builtin(vertex_index) idx: u32) -> @builtin(position) vec4f {
        \\    var pos = array(vec2f(0,1), vec2f(-1,-1), vec2f(1,-1));
        \\    return vec4f(pos[idx], 0, 1);
        \\}
        \\@fragment fn fs_main() -> @location(0) vec4f {
        \\    return vec4f(1, 0, 0, 1);
        \\}
    });
    defer shader.deinit();

    // Create pipeline
    const pipeline = try device.createRenderPipeline(.{
        .vertex_shader = shader,
        .fragment_shader = shader,
        .color_target_format = .bgra8_unorm,
    });
    defer pipeline.deinit();

    // Render loop
    while (!window.shouldClose()) {
        window.pollEvents();

        const surface_tex = try surface.getCurrentTexture();
        const view = dawn.TextureView{ .handle = raw.wgpuTextureCreateView(surface_tex.texture, null) };
        defer view.deinit();

        var encoder = try device.createCommandEncoder();
        {
            var pass = encoder.beginRenderPass(.{
                .color_attachments = &[_]dawn.types.RenderPassColorAttachment{.{
                    .view = view.handle,
                    .load_op = .clear,
                    .store_op = .store,
                    .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
                }},
            });

            pass.setPipeline(pipeline);
            pass.draw(3, 1, 0, 0);
            pass.end();
        }

        const cmd_buf = try encoder.finish();
        defer cmd_buf.deinit();

        queue.submit(&[_]dawn.CommandBuffer{cmd_buf});
        surface.present();
    }
}
```

---

## Phase 2: Advanced Features (Future)

- Vertex buffers with attributes
- Index buffers
- Uniform buffers & bind groups
- Textures & samplers
- Depth/stencil
- Compute pipelines

---

## Key Benefits of This Approach

### Files as Structs

✅ **No Redundancy** - File IS the struct, no extra nesting  
✅ **Clean Imports** - `const Instance = @import("instance.zig");`  
✅ **Self-Documenting** - One type per file, clear responsibility  
✅ **Idiomatic Zig** - Uses language features as intended

### Type Safety

✅ **Zig Enums** - Not raw C integers  
✅ **Error Unions** - Explicit error handling  
✅ **Compile-Time Checks** - `.toRaw()` validates at comptime

### Zero Cost

✅ **Direct C Calls** - No wrapper overhead  
✅ **Inline Everything** - Compiler optimizes it all away  
✅ **Stack Allocated** - Descriptors don't allocate

### Maintainability

✅ **Single Source of Truth** - webgpu.h via @cImport  
✅ **Easy Updates** - Swap header, rebuild  
✅ **Modular** - Each file is independent

---

## Implementation Timeline

- **Week 1:** Type system + Core objects (Instance, Surface, Adapter, Device, Queue)
- **Week 2:** Pipeline objects (Shader, RenderPipeline) + Command recording
- **Week 3:** Resources (Buffer, Texture) + Utilities (sync helpers)
- **Week 4:** Integration + Triangle example + Testing

**End of Phase 1:** Rotating triangle in window using clean Zig API!
