const std = @import("std");
const dawn = @import("dawn");

pub fn main() !void {
    std.log.info("Testing if Dawn DLL loads...", .{});

    // Just try to create an instance - if this works, DLL is loaded
    const instance = dawn.createInstance(null);
    if (instance) |inst| {
        std.log.info("✅ SUCCESS: Dawn DLL loaded and WebGPU instance created!", .{});
        dawn.instanceRelease(inst);
    } else {
        std.log.err("❌ FAILED: Dawn DLL not loaded - instance creation returned null", .{});
        return error.DLLNotLoaded;
    }
}
