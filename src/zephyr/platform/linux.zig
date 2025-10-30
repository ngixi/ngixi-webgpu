const std = @import("std");
const App = @import("../app.zig").App;
const Window = @import("../window.zig").Window;
const WindowOptions = @import("../window.zig").WindowOptions;

// Linux placeholder implementation
// TODO: Implement with X11 or Wayland

pub fn createApp(allocator: std.mem.Allocator) !App {
    _ = allocator;
    return error.NotImplemented;
}