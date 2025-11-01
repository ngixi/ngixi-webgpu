// Adapter - Represents a physical GPU adapter
// This file IS the Adapter struct (files-as-structs pattern)

const std = @import("std");
const raw = @import("../raw/c.zig").c;
const sync = @import("../utils/sync.zig");
const enums = @import("../types/enums.zig");

// This makes the file a struct
handle: raw.WGPUAdapter,
instance: raw.WGPUInstance,

/// Get detailed information about this adapter
/// Caller must call info.deinit() when done
pub fn getInfo(self: @This()) !AdapterInfo {
    var raw_info: raw.WGPUAdapterInfo = std.mem.zeroes(raw.WGPUAdapterInfo);
    raw_info.nextInChain = null;

    const status = raw.wgpuAdapterGetInfo(self.handle, &raw_info);
    if (status != raw.WGPUStatus_Success) {
        return error.FailedToGetAdapterInfo;
    }

    return AdapterInfo.fromRaw(raw_info);
}

/// Request a device from this adapter
pub fn requestDevice(self: @This(), descriptor: ?DeviceDescriptor) !Device {
    const raw_desc = if (descriptor) |d| blk: {
        var desc = d.toRaw();
        break :blk &desc;
    } else null;

    const device_handle = try sync.requestDeviceSync(self.instance, self.handle, raw_desc);
    return Device{ .handle = device_handle };
}

/// Check if this adapter has a specific feature
pub fn hasFeature(self: @This(), feature: enums.FeatureName) bool {
    return raw.wgpuAdapterHasFeature(self.handle, feature.toRaw()) == raw.WGPU_TRUE;
}

/// Enumerate all supported features
/// Caller owns the returned slice
pub fn enumerateFeatures(self: @This(), allocator: std.mem.Allocator) ![]enums.FeatureName {
    var supported: raw.WGPUSupportedFeatures = undefined;
    raw.wgpuAdapterGetFeatures(self.handle, &supported);
    defer raw.wgpuSupportedFeaturesFreeMembers(supported);

    if (supported.featureCount == 0) return &[_]enums.FeatureName{};

    const features = try allocator.alloc(enums.FeatureName, supported.featureCount);
    for (0..supported.featureCount) |i| {
        features[i] = enums.FeatureName.fromRaw(supported.features[i]);
    }

    return features;
}

/// Release the adapter
pub fn deinit(self: @This()) void {
    raw.wgpuAdapterRelease(self.handle);
}

// === Types for this module ===

/// Detailed information about an adapter
pub const AdapterInfo = struct {
    vendor: []const u8,
    architecture: []const u8,
    device: []const u8,
    description: []const u8,
    backend_type: enums.BackendType,
    adapter_type: enums.AdapterType,
    vendor_id: u32,
    device_id: u32,

    // Internal: we need to track the raw strings to free them
    _raw_info: raw.WGPUAdapterInfo,

    pub fn fromRaw(raw_info: raw.WGPUAdapterInfo) AdapterInfo {
        return .{
            .vendor = stringViewToSlice(raw_info.vendor),
            .architecture = stringViewToSlice(raw_info.architecture),
            .device = stringViewToSlice(raw_info.device),
            .description = stringViewToSlice(raw_info.description),
            .backend_type = enums.BackendType.fromRaw(raw_info.backendType),
            .adapter_type = enums.AdapterType.fromRaw(raw_info.adapterType),
            .vendor_id = raw_info.vendorID,
            .device_id = raw_info.deviceID,
            ._raw_info = raw_info,
        };
    }

    pub fn deinit(self: @This()) void {
        raw.wgpuAdapterInfoFreeMembers(self._raw_info);
    }

    /// Print adapter info in a nice format
    pub fn print(self: AdapterInfo) void {
        std.debug.print("\n=== GPU Adapter Info ===\n", .{});
        std.debug.print("  Device: {s}\n", .{self.device});
        std.debug.print("  Description: {s}\n", .{self.description});
        std.debug.print("  Vendor: {s} (ID: 0x{X:0>4})\n", .{ self.vendor, self.vendor_id });
        std.debug.print("  Architecture: {s}\n", .{self.architecture});
        std.debug.print("  Backend: {s}\n", .{self.backend_type.name()});
        std.debug.print("  Type: {s}\n", .{@tagName(self.adapter_type)});
        std.debug.print("  Device ID: 0x{X:0>4}\n", .{self.device_id});
        std.debug.print("========================\n\n", .{});
    }
};

/// Options for requesting a device
pub const DeviceDescriptor = struct {
    label: ?[]const u8 = null,

    pub fn toRaw(self: DeviceDescriptor) raw.WGPUDeviceDescriptor {
        _ = self;
        return .{
            .nextInChain = null,
            .label = .{ .data = null, .length = 0 },
            .requiredFeatureCount = 0,
            .requiredFeatures = null,
            .requiredLimits = null,
            .defaultQueue = .{
                .nextInChain = null,
                .label = .{ .data = null, .length = 0 },
            },
            .deviceLostCallbackInfo = .{
                .nextInChain = null,
                .mode = raw.WGPUCallbackMode_AllowSpontaneous,
                .callback = null,
                .userdata1 = null,
                .userdata2 = null,
            },
            .uncapturedErrorCallbackInfo = .{
                .nextInChain = null,
                .callback = null,
                .userdata1 = null,
                .userdata2 = null,
            },
        };
    }
};

// Helper to convert WGPUStringView to Zig slice
fn stringViewToSlice(sv: raw.WGPUStringView) []const u8 {
    if (sv.data == null or sv.length == 0) return "";
    return sv.data[0..sv.length];
}

// Forward declaration
const Device = @import("device.zig");
