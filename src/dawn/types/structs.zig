// Common WebGPU structures with .toRaw() methods for C interop
// These are pure data types, not "files as structs" pattern

const raw = @import("../raw/c.zig").c;

/// RGBA color value with floating point components
pub const Color = struct {
    r: f64,
    g: f64,
    b: f64,
    a: f64,

    pub fn toRaw(self: Color) raw.WGPUColor {
        return .{
            .r = self.r,
            .g = self.g,
            .b = self.b,
            .a = self.a,
        };
    }

    pub fn fromRaw(value: raw.WGPUColor) Color {
        return .{
            .r = value.r,
            .g = value.g,
            .b = value.b,
            .a = value.a,
        };
    }

    /// Common color constants
    pub const black = Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 };
    pub const white = Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 };
    pub const red = Color{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 };
    pub const green = Color{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 };
    pub const blue = Color{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 };
    pub const transparent = Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };
};

/// 3D extent (width, height, depth)
pub const Extent3D = struct {
    width: u32,
    height: u32 = 1,
    depth_or_array_layers: u32 = 1,

    pub fn toRaw(self: Extent3D) raw.WGPUExtent3D {
        return .{
            .width = self.width,
            .height = self.height,
            .depthOrArrayLayers = self.depth_or_array_layers,
        };
    }

    pub fn fromRaw(value: raw.WGPUExtent3D) Extent3D {
        return .{
            .width = value.width,
            .height = value.height,
            .depth_or_array_layers = value.depthOrArrayLayers,
        };
    }
};

/// 3D origin point
pub const Origin3D = struct {
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,

    pub fn toRaw(self: Origin3D) raw.WGPUOrigin3D {
        return .{
            .x = self.x,
            .y = self.y,
            .z = self.z,
        };
    }

    pub fn fromRaw(value: raw.WGPUOrigin3D) Origin3D {
        return .{
            .x = value.x,
            .y = value.y,
            .z = value.z,
        };
    }
};

/// 2D extent (width, height)
pub const Extent2D = struct {
    width: u32,
    height: u32,

    pub fn toRaw(self: Extent2D) raw.WGPUExtent2D {
        return .{
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn fromRaw(value: raw.WGPUExtent2D) Extent2D {
        return .{
            .width = value.width,
            .height = value.height,
        };
    }
};

/// 2D origin point
pub const Origin2D = struct {
    x: u32 = 0,
    y: u32 = 0,

    pub fn toRaw(self: Origin2D) raw.WGPUOrigin2D {
        return .{
            .x = self.x,
            .y = self.y,
        };
    }

    pub fn fromRaw(value: raw.WGPUOrigin2D) Origin2D {
        return .{
            .x = value.x,
            .y = value.y,
        };
    }
};
