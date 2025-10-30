// Queue - Command queue for GPU operations
// This file IS the Queue struct (files-as-structs pattern)

const raw = @import("../raw/c.zig").c;

// This makes the file a struct
handle: raw.WGPUQueue,

/// Release the queue
pub fn deinit(self: @This()) void {
    raw.wgpuQueueRelease(self.handle);
}
