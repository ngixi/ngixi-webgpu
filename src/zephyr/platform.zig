const std = @import("std");
const builtin = @import("builtin");
const App = @import("app.zig").App;
const Window = @import("window.zig").Window;
const WindowOptions = @import("window.zig").WindowOptions;

// Platform detection and dispatch
pub const PlatformType = enum {
    windows,
    linux,
    macos,
    unknown,
};

pub fn getCurrentPlatform() PlatformType {
    const target = builtin.target;
    if (target.os.tag == .windows) {
        return .windows;
    } else if (target.os.tag == .linux) {
        return .linux;
    } else if (target.os.tag == .macos) {
        return .macos;
    } else {
        return .unknown;
    }
}

pub fn createApp(allocator: std.mem.Allocator) !App {
    const platform = getCurrentPlatform();
    switch (platform) {
        .windows => {
            const windows = @import("platform/windows.zig");
            return windows.createApp(allocator);
        },
        .linux => {
            const linux = @import("platform/linux.zig");
            return linux.createApp(allocator);
        },
        .macos => {
            const macos = @import("platform/macos.zig");
            return macos.createApp(allocator);
        },
        .unknown => {
            return error.UnsupportedPlatform;
        },
    }
}