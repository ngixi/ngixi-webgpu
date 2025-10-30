const std = @import("std");
const Event = @import("event.zig").Event;
const GraphicsContext = @import("graphics.zig").GraphicsContext;

// Cross-platform window interface
pub const Window = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    
    pub const Size = struct { width: i32, height: i32 };
    pub const Position = struct { x: i32, y: i32 };
    
    pub const VTable = struct {
        show: *const fn (window: *anyopaque) void,
        hide: *const fn (window: *anyopaque) void,
        close: *const fn (window: *anyopaque) void,
        setTitle: *const fn (window: *anyopaque, title: []const u8) void,
        getTitle: *const fn (window: *anyopaque, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8,
        setSize: *const fn (window: *anyopaque, width: i32, height: i32) void,
        getSize: *const fn (window: *anyopaque) Size,
        setPosition: *const fn (window: *anyopaque, x: i32, y: i32) void,
        getPosition: *const fn (window: *anyopaque) Position,
        beginPaint: *const fn (window: *anyopaque) GraphicsContext,
        endPaint: *const fn (window: *anyopaque, ctx: GraphicsContext) void,
        invalidate: *const fn (window: *anyopaque) void,
        setEventHandler: *const fn (window: *anyopaque, handler: ?*const fn (window: *Window, event: Event) void) void,
        getNativeHandle: *const fn (window: *anyopaque) *anyopaque,
        deinit: *const fn (window: *anyopaque) void,
    };
    
    pub fn show(self: Window) void {
        self.vtable.show(self.ptr);
    }
    
    pub fn hide(self: Window) void {
        self.vtable.hide(self.ptr);
    }
    
    pub fn close(self: Window) void {
        self.vtable.close(self.ptr);
    }
    
    pub fn setTitle(self: Window, title: []const u8) void {
        self.vtable.setTitle(self.ptr, title);
    }
    
    pub fn getTitle(self: Window, allocator: std.mem.Allocator) ![]u8 {
        return self.vtable.getTitle(self.ptr, allocator);
    }
    
    pub fn setSize(self: Window, width: i32, height: i32) void {
        self.vtable.setSize(self.ptr, width, height);
    }
    
    pub fn getSize(self: Window) Size {
        return self.vtable.getSize(self.ptr);
    }
    
    pub fn setPosition(self: Window, x: i32, y: i32) void {
        self.vtable.setPosition(self.ptr, x, y);
    }
    
    pub fn getPosition(self: Window) Position {
        return self.vtable.getPosition(self.ptr);
    }
    
    pub fn beginPaint(self: Window) GraphicsContext {
        return self.vtable.beginPaint(self.ptr);
    }
    
    pub fn endPaint(self: Window, ctx: GraphicsContext) void {
        self.vtable.endPaint(self.ptr, ctx);
    }
    
    pub fn invalidate(self: Window) void {
        self.vtable.invalidate(self.ptr);
    }
    
    pub fn setEventHandler(self: Window, handler: ?*const fn (window: *Window, event: Event) void) void {
        self.vtable.setEventHandler(self.ptr, handler);
    }
    
    pub fn getNativeHandle(self: Window) *anyopaque {
        return self.vtable.getNativeHandle(self.ptr);
    }
    
    pub fn deinit(self: Window) void {
        self.vtable.deinit(self.ptr);
    }
};

// Window creation options
pub const WindowOptions = struct {
    title: []const u8 = "Zephyr Window",
    width: i32 = 800,
    height: i32 = 600,
    x: i32 = -1, // -1 for centered
    y: i32 = -1, // -1 for centered
    resizable: bool = true,
    visible: bool = true,
    decorated: bool = true,
    always_on_top: bool = false,
    fullscreen: bool = false,
};