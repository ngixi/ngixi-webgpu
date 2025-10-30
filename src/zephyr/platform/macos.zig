const std = @import("std");
const App = @import("../app.zig").App;
const Window = @import("../window.zig").Window;
const WindowOptions = @import("../window.zig").WindowOptions;

// macOS placeholder implementation
// TODO: Implement with Cocoa/AppKit

pub fn createApp(allocator: std.mem.Allocator) !App {
    _ = allocator;
    return error.NotImplemented;
}