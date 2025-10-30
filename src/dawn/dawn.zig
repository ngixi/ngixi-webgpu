const std = @import("std");
const raw = @import("raw/c.zig");

// BARE MINIMUM WebGPU bindings to test DLL loading
// Now using @cImport for automatic C binding

pub const WGPUInstance = raw.WGPUInstance;
pub const WGPUInstanceDescriptor = raw.WGPUInstanceDescriptor;

// Wrapper functions
pub fn createInstance(descriptor: ?*const WGPUInstanceDescriptor) WGPUInstance {
    return raw.c.wgpuCreateInstance(descriptor);
}

pub fn instanceRelease(instance: WGPUInstance) void {
    raw.c.wgpuInstanceRelease(instance);
}
