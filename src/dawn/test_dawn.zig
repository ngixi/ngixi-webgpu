const std = @import("std");
const dawn = @import("dawn");

pub fn main() !void {
    std.log.info("Testing if Dawn DLL loads...", .{});

    // Try to create an instance using the new API
    const instance = try dawn.Instance.init(null);
    defer instance.deinit();
    
    std.log.info("✅ SUCCESS: Dawn DLL loaded and WebGPU instance created!", .{});
}
