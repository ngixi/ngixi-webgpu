// Raw C bindings to WebGPU Dawn
// This imports the official webgpu.h header from the Dawn dependency

pub const c = @cImport({
    @cInclude("webgpu.h");
});

// Re-export commonly used types for convenience
pub const WGPUInstance = c.WGPUInstance;
pub const WGPUAdapter = c.WGPUAdapter;
pub const WGPUDevice = c.WGPUDevice;
pub const WGPUQueue = c.WGPUQueue;
pub const WGPUSurface = c.WGPUSurface;
pub const WGPUTexture = c.WGPUTexture;
pub const WGPUTextureView = c.WGPUTextureView;
pub const WGPUBuffer = c.WGPUBuffer;
pub const WGPUShaderModule = c.WGPUShaderModule;
pub const WGPURenderPipeline = c.WGPURenderPipeline;
pub const WGPUCommandEncoder = c.WGPUCommandEncoder;
pub const WGPURenderPassEncoder = c.WGPURenderPassEncoder;
pub const WGPUCommandBuffer = c.WGPUCommandBuffer;

// Re-export descriptor types
pub const WGPUInstanceDescriptor = c.WGPUInstanceDescriptor;
