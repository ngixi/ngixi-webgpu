// Instance - The entry point for WebGPU
// This file IS the Instance struct (files-as-structs pattern)
// No redundant wrapping - just import and use!

const std = @import("std");
const raw = @import("../raw/c.zig").c;
const sync = @import("../utils/sync.zig");
const enums = @import("../types/enums.zig");

// This makes the file a struct - the handle is the root field
handle: raw.WGPUInstance,

/// Initialize a new WebGPU instance
/// This is the entry point for all WebGPU operations
pub fn init(desc: ?Descriptor) !@This() {
    const raw_desc = if (desc) |d| blk: {
        var descriptor = d.toRaw();
        break :blk &descriptor;
    } else null;

    const handle = raw.wgpuCreateInstance(raw_desc);
    if (handle == null) return error.InstanceCreateFailed;

    return .{ .handle = handle.? };
}

/// Release the instance and free resources
pub fn deinit(self: @This()) void {
    raw.wgpuInstanceRelease(self.handle);
}

/// Request an adapter (graphics device)
/// This is how you enumerate and select which GPU to use
pub fn requestAdapter(self: @This(), options: RequestAdapterOptions) !Adapter {
    var raw_opts = options.toRaw();
    const adapter_handle = try sync.requestAdapterSync(self.handle, &raw_opts);

    return Adapter{
        .handle = adapter_handle,
        .instance = self.handle,
    };
}

/// Process events - call this regularly in your main loop
pub fn processEvents(self: @This()) void {
    _ = raw.wgpuInstanceProcessEvents(self.handle);
}

/// Wait for any pending operations to complete
pub fn waitAny(self: @This(), timeout_ns: u64) void {
    const future = raw.WGPUFuture{ .id = 0 };
    _ = raw.wgpuInstanceWaitAny(self.handle, 1, &future, timeout_ns);
}

// === Descriptor types for this module ===

/// Options for requesting an adapter
pub const RequestAdapterOptions = struct {
    /// Optional surface for compatibility checks
    compatible_surface: ?Surface = null,
    /// Power preference hint
    power_preference: enums.PowerPreference = .undefined,
    /// Force specific backend (D3D12, Vulkan, Metal, etc.)
    backend_type: ?enums.BackendType = null,
    /// Whether to allow fallback adapters
    force_fallback_adapter: bool = false,

    pub fn toRaw(self: RequestAdapterOptions) raw.WGPURequestAdapterOptions {
        return .{
            .nextInChain = null,
            .compatibleSurface = if (self.compatible_surface) |s| s.handle else null,
            .powerPreference = self.power_preference.toRaw(),
            .backendType = if (self.backend_type) |bt| bt.toRaw() else raw.WGPUBackendType_Undefined,
            .forceFallbackAdapter = if (self.force_fallback_adapter) raw.WGPU_TRUE else raw.WGPU_FALSE,
        };
    }
};

/// Descriptor for instance creation
pub const Descriptor = struct {
    /// Features to enable (optional)
    features: ?[]const enums.FeatureName = null,

    pub fn toRaw(self: Descriptor) raw.WGPUInstanceDescriptor {
        _ = self;
        // For now, return a basic descriptor
        // In the future, we can add feature configuration here
        return .{
            .nextInChain = null,
        };
    }
};

// Forward declarations for types used by Instance
const Adapter = @import("adapter.zig");
const Surface = @import("surface.zig");
