const std = @import("std");

// Main public API - re-export everything
// This is the entry point for using Dawn WebGPU in Zig

// === Core Objects (files as structs) ===
pub const Instance = @import("core/instance.zig");
pub const Adapter = @import("core/adapter.zig");
pub const Device = @import("core/device.zig");
pub const Queue = @import("core/queue.zig");
pub const Surface = @import("core/surface.zig");

// === Types ===
pub const enums = @import("types/enums.zig");
pub const structs = @import("types/structs.zig");

// Re-export commonly used types at the top level for convenience
pub const BackendType = enums.BackendType;
pub const AdapterType = enums.AdapterType;
pub const PowerPreference = enums.PowerPreference;
pub const TextureFormat = enums.TextureFormat;
pub const PresentMode = enums.PresentMode;
pub const FeatureName = enums.FeatureName;
pub const Color = structs.Color;
pub const Extent3D = structs.Extent3D;
pub const Origin3D = structs.Origin3D;

// === Raw C Bindings (for advanced users) ===
pub const raw = @import("raw/c.zig");

// === Version Info ===
pub const version = "0.1.0";
pub const api_name = "Dawn WebGPU";

test "dawn imports" {
    std.testing.refAllDecls(@This());
}
