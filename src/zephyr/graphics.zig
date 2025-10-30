const std = @import("std");

// Cross-platform graphics context interface
pub const GraphicsContext = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    
    pub const VTable = struct {
        clear: *const fn (ctx: *anyopaque, color: Color) void,
        drawText: *const fn (ctx: *anyopaque, text: []const u8, x: i32, y: i32, color: Color) void,
        drawRect: *const fn (ctx: *anyopaque, x: i32, y: i32, width: i32, height: i32, color: Color) void,
        drawLine: *const fn (ctx: *anyopaque, x1: i32, y1: i32, x2: i32, y2: i32, color: Color) void,
        setClipRect: *const fn (ctx: *anyopaque, x: i32, y: i32, width: i32, height: i32) void,
        resetClipRect: *const fn (ctx: *anyopaque) void,
        deinit: *const fn (ctx: *anyopaque) void,
    };
    
    pub fn clear(self: GraphicsContext, color: Color) void {
        self.vtable.clear(self.ptr, color);
    }
    
    pub fn drawText(self: GraphicsContext, text: []const u8, x: i32, y: i32, color: Color) void {
        self.vtable.drawText(self.ptr, text, x, y, color);
    }
    
    pub fn drawRect(self: GraphicsContext, x: i32, y: i32, width: i32, height: i32, color: Color) void {
        self.vtable.drawRect(self.ptr, x, y, width, height, color);
    }
    
    pub fn drawLine(self: GraphicsContext, x1: i32, y1: i32, x2: i32, y2: i32, color: Color) void {
        self.vtable.drawLine(self.ptr, x1, y1, x2, y2, color);
    }
    
    pub fn setClipRect(self: GraphicsContext, x: i32, y: i32, width: i32, height: i32) void {
        self.vtable.setClipRect(self.ptr, x, y, width, height);
    }
    
    pub fn resetClipRect(self: GraphicsContext) void {
        self.vtable.resetClipRect(self.ptr);
    }
    
    pub fn deinit(self: GraphicsContext) void {
        self.vtable.deinit(self.ptr);
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,
    
    pub const white: Color = .{ .r = 255, .g = 255, .b = 255 };
    pub const black: Color = .{ .r = 0, .g = 0, .b = 0 };
    pub const red: Color = .{ .r = 255, .g = 0, .b = 0 };
    pub const green: Color = .{ .r = 0, .g = 255, .b = 0 };
    pub const blue: Color = .{ .r = 0, .g = 0, .b = 255 };
    pub const yellow: Color = .{ .r = 255, .g = 255, .b = 0 };
    pub const magenta: Color = .{ .r = 255, .g = 0, .b = 255 };
    pub const cyan: Color = .{ .r = 0, .g = 255, .b = 255 };
    pub const gray: Color = .{ .r = 128, .g = 128, .b = 128 };
    pub const dark_gray: Color = .{ .r = 64, .g = 64, .b = 64 };
    pub const light_gray: Color = .{ .r = 192, .g = 192, .b = 192 };
    pub const transparent: Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
    
    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = 255 };
    }
    
    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }
    
    pub fn toU32(self: Color) u32 {
        // Windows GDI expects BGR format: 0x00BBGGRR
        return (@as(u32, self.b) << 16) | (@as(u32, self.g) << 8) | @as(u32, self.r);
    }
    
    pub fn fromU32(value: u32) Color {
        // Windows GDI format: 0x00BBGGRR
        return .{
            .r = @intCast((value >> 16) & 0xFF),
            .g = @intCast((value >> 8) & 0xFF),
            .b = @intCast(value & 0xFF),
            .a = 255,
        };
    }
};