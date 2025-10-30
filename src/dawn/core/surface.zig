// Surface - Represents a platform surface for rendering
// This file IS the Surface struct (files-as-structs pattern)

const raw = @import("../raw/c.zig").c;

// This makes the file a struct
handle: raw.WGPUSurface,

/// Release the surface
pub fn deinit(self: @This()) void {
    raw.wgpuSurfaceRelease(self.handle);
}

// More methods will be added as we build out the API
