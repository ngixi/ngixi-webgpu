const std = @import("std");
const Window = @import("window.zig").Window;
const WindowOptions = @import("window.zig").WindowOptions;

// Cross-platform application interface
pub const App = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    
    pub const Error = error{
        OutOfMemory,
        WindowCreationFailed,
        AlreadyInitialized,
    };
    
    pub const VTable = struct {
        createWindow: *const fn (app: *anyopaque, options: WindowOptions) App.Error!Window,
        run: *const fn (app: *anyopaque) i32,
        quit: *const fn (app: *anyopaque) void,
        getAllocator: *const fn (app: *anyopaque) std.mem.Allocator,
        deinit: *const fn (app: *anyopaque) void,
    };
    
    pub fn createWindow(self: App, options: WindowOptions) !Window {
        return self.vtable.createWindow(self.ptr, options);
    }
    
    pub fn run(self: App) i32 {
        return self.vtable.run(self.ptr);
    }
    
    pub fn quit(self: App) void {
        self.vtable.quit(self.ptr);
    }
    
    pub fn getAllocator(self: App) std.mem.Allocator {
        return self.vtable.getAllocator(self.ptr);
    }
    
    pub fn deinit(self: App) void {
        self.vtable.deinit(self.ptr);
    }
};

// Global app instance management
var global_app: ?App = null;

pub fn init(allocator: std.mem.Allocator) !App {
    if (global_app != null) {
        return error.AlreadyInitialized;
    }
    
    // Import the platform-specific implementation
    const platform = @import("platform.zig");
    const app = try platform.createApp(allocator);
    global_app = app;
    return app;
}

pub fn get() ?App {
    return global_app;
}

pub fn deinit() void {
    if (global_app) |app| {
        app.deinit();
        global_app = null;
    }
}

// Convenience functions for single-window apps
pub fn runSingleWindow(
    allocator: std.mem.Allocator,
    options: WindowOptions,
    event_handler: ?*const fn (window: *Window, event: @import("event.zig").Event) void
) !i32 {
    var app = try init(allocator);
    defer deinit();
    
    var window = try app.createWindow(options);
    // Don't defer window.deinit() - app.deinit() will handle it
    
    if (event_handler) |handler| {
        window.setEventHandler(handler);
    }
    
    window.show();
    // Trigger initial paint
    window.invalidate();
    return app.run();
}