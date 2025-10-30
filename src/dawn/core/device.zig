// Device - Represents a logical GPU device
// This file IS the Device struct (files-as-structs pattern)

const std = @import("std");
const raw = @import("../raw/c.zig").c;

// This makes the file a struct
handle: raw.WGPUDevice,

/// Get the device's command queue
pub fn getQueue(self: @This()) Queue {
    const handle = raw.wgpuDeviceGetQueue(self.handle);
    return Queue{ .handle = handle };
}

/// Release the device
pub fn deinit(self: @This()) void {
    raw.wgpuDeviceRelease(self.handle);
}

// Forward declaration
const Queue = @import("queue.zig");
