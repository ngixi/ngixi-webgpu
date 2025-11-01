// Zig-idiomatic enums that map to WebGPU enums
// These provide type safety and clean naming while converting to raw C types via toRaw()

const raw = @import("../raw/c.zig").c;

/// Indicates what type of GPU adapter this is
pub const AdapterType = enum(u32) {
    discrete_gpu = 0x00000001,
    integrated_gpu = 0x00000002,
    cpu = 0x00000003,
    unknown = 0x00000004,

    pub fn toRaw(self: AdapterType) raw.WGPUAdapterType {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUAdapterType) AdapterType {
        return @enumFromInt(value);
    }
};

/// The backend API used by the GPU adapter (D3D12, Vulkan, Metal, etc.)
pub const BackendType = enum(u32) {
    undefined = 0x00000000,
    null = 0x00000001,
    webgpu = 0x00000002,
    d3d11 = 0x00000003,
    d3d12 = 0x00000004,
    metal = 0x00000005,
    vulkan = 0x00000006,
    opengl = 0x00000007,
    opengles = 0x00000008,

    pub fn toRaw(self: BackendType) raw.WGPUBackendType {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUBackendType) BackendType {
        return @enumFromInt(value);
    }

    /// Returns a human-readable name for the backend
    pub fn name(self: BackendType) []const u8 {
        return switch (self) {
            .undefined => "Undefined",
            .null => "Null",
            .webgpu => "WebGPU",
            .d3d11 => "Direct3D 11",
            .d3d12 => "Direct3D 12",
            .metal => "Metal",
            .vulkan => "Vulkan",
            .opengl => "OpenGL",
            .opengles => "OpenGL ES",
        };
    }
};

/// Power preference for adapter selection
pub const PowerPreference = enum(u32) {
    undefined = 0x00000000,
    low_power = 0x00000001,
    high_performance = 0x00000002,

    pub fn toRaw(self: PowerPreference) raw.WGPUPowerPreference {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUPowerPreference) PowerPreference {
        return @enumFromInt(value);
    }
};

/// Texture formats supported by WebGPU
pub const TextureFormat = enum(u32) {
    undefined = 0x00000000,
    r8_unorm = 0x00000001,
    r8_snorm = 0x00000002,
    r8_uint = 0x00000003,
    r8_sint = 0x00000004,
    r16_uint = 0x00000005,
    r16_sint = 0x00000006,
    r16_float = 0x00000007,
    rg8_unorm = 0x00000008,
    rg8_snorm = 0x00000009,
    rg8_uint = 0x0000000A,
    rg8_sint = 0x0000000B,
    r32_float = 0x0000000C,
    r32_uint = 0x0000000D,
    r32_sint = 0x0000000E,
    rg16_uint = 0x0000000F,
    rg16_sint = 0x00000010,
    rg16_float = 0x00000011,
    rgba8_unorm = 0x00000012,
    rgba8_unorm_srgb = 0x00000013,
    rgba8_snorm = 0x00000014,
    rgba8_uint = 0x00000015,
    rgba8_sint = 0x00000016,
    bgra8_unorm = 0x00000017,
    bgra8_unorm_srgb = 0x00000018,
    rgb10a2_uint = 0x00000019,
    rgb10a2_unorm = 0x0000001A,
    rg11b10_ufloat = 0x0000001B,
    rgb9e5_ufloat = 0x0000001C,
    rg32_float = 0x0000001D,
    rg32_uint = 0x0000001E,
    rg32_sint = 0x0000001F,
    rgba16_uint = 0x00000020,
    rgba16_sint = 0x00000021,
    rgba16_float = 0x00000022,
    rgba32_float = 0x00000023,
    rgba32_uint = 0x00000024,
    rgba32_sint = 0x00000025,
    stencil8 = 0x00000026,
    depth16_unorm = 0x00000027,
    depth24_plus = 0x00000028,
    depth24_plus_stencil8 = 0x00000029,
    depth32_float = 0x0000002A,
    depth32_float_stencil8 = 0x0000002B,
    bc1_rgba_unorm = 0x0000002C,
    bc1_rgba_unorm_srgb = 0x0000002D,
    bc2_rgba_unorm = 0x0000002E,
    bc2_rgba_unorm_srgb = 0x0000002F,
    bc3_rgba_unorm = 0x00000030,
    bc3_rgba_unorm_srgb = 0x00000031,
    bc4_r_unorm = 0x00000032,
    bc4_r_snorm = 0x00000033,
    bc5_rg_unorm = 0x00000034,
    bc5_rg_snorm = 0x00000035,
    bc6h_rgb_ufloat = 0x00000036,
    bc6h_rgb_float = 0x00000037,
    bc7_rgba_unorm = 0x00000038,
    bc7_rgba_unorm_srgb = 0x00000039,
    etc2_rgb8_unorm = 0x0000003A,
    etc2_rgb8_unorm_srgb = 0x0000003B,
    etc2_rgb8a1_unorm = 0x0000003C,
    etc2_rgb8a1_unorm_srgb = 0x0000003D,
    etc2_rgba8_unorm = 0x0000003E,
    etc2_rgba8_unorm_srgb = 0x0000003F,
    eac_r11_unorm = 0x00000040,
    eac_r11_snorm = 0x00000041,
    eac_rg11_unorm = 0x00000042,
    eac_rg11_snorm = 0x00000043,
    astc4x4_unorm = 0x00000044,
    astc4x4_unorm_srgb = 0x00000045,
    astc5x4_unorm = 0x00000046,
    astc5x4_unorm_srgb = 0x00000047,
    astc5x5_unorm = 0x00000048,
    astc5x5_unorm_srgb = 0x00000049,
    astc6x5_unorm = 0x0000004A,
    astc6x5_unorm_srgb = 0x0000004B,
    astc6x6_unorm = 0x0000004C,
    astc6x6_unorm_srgb = 0x0000004D,
    astc8x5_unorm = 0x0000004E,
    astc8x5_unorm_srgb = 0x0000004F,
    astc8x6_unorm = 0x00000050,
    astc8x6_unorm_srgb = 0x00000051,
    astc8x8_unorm = 0x00000052,
    astc8x8_unorm_srgb = 0x00000053,
    astc10x5_unorm = 0x00000054,
    astc10x5_unorm_srgb = 0x00000055,
    astc10x6_unorm = 0x00000056,
    astc10x6_unorm_srgb = 0x00000057,
    astc10x8_unorm = 0x00000058,
    astc10x8_unorm_srgb = 0x00000059,
    astc10x10_unorm = 0x0000005A,
    astc10x10_unorm_srgb = 0x0000005B,
    astc12x10_unorm = 0x0000005C,
    astc12x10_unorm_srgb = 0x0000005D,
    astc12x12_unorm = 0x0000005E,
    astc12x12_unorm_srgb = 0x0000005F,

    pub fn toRaw(self: TextureFormat) raw.WGPUTextureFormat {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUTextureFormat) TextureFormat {
        return @enumFromInt(value);
    }
};

/// Present mode for surface presentation
pub const PresentMode = enum(u32) {
    immediate = 0x00000001,
    mailbox = 0x00000002,
    fifo = 0x00000003,

    pub fn toRaw(self: PresentMode) raw.WGPUPresentMode {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUPresentMode) PresentMode {
        return @enumFromInt(value);
    }
};

/// Load operation for render pass attachments
pub const LoadOp = enum(u32) {
    undefined = 0x00000000,
    clear = 0x00000001,
    load = 0x00000002,

    pub fn toRaw(self: LoadOp) raw.WGPULoadOp {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPULoadOp) LoadOp {
        return @enumFromInt(value);
    }
};

/// Store operation for render pass attachments
pub const StoreOp = enum(u32) {
    undefined = 0x00000000,
    store = 0x00000001,
    discard = 0x00000002,

    pub fn toRaw(self: StoreOp) raw.WGPUStoreOp {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUStoreOp) StoreOp {
        return @enumFromInt(value);
    }
};

/// Primitive topology for rendering
pub const PrimitiveTopology = enum(u32) {
    point_list = 0x00000001,
    line_list = 0x00000002,
    line_strip = 0x00000003,
    triangle_list = 0x00000004,
    triangle_strip = 0x00000005,

    pub fn toRaw(self: PrimitiveTopology) raw.WGPUPrimitiveTopology {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUPrimitiveTopology) PrimitiveTopology {
        return @enumFromInt(value);
    }
};

/// Composite alpha mode for surface configuration
pub const CompositeAlphaMode = enum(u32) {
    auto = 0x00000000,
    @"opaque" = 0x00000001,
    premultiplied = 0x00000002,
    unpremultiplied = 0x00000003,
    inherit = 0x00000004,

    pub fn toRaw(self: CompositeAlphaMode) raw.WGPUCompositeAlphaMode {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUCompositeAlphaMode) CompositeAlphaMode {
        return @enumFromInt(value);
    }
};

/// Error types for error handling
pub const ErrorType = enum(u32) {
    no_error = 0x00000001,
    validation = 0x00000002,
    out_of_memory = 0x00000003,
    internal = 0x00000004,
    unknown = 0x00000005,

    pub fn toRaw(self: ErrorType) raw.WGPUErrorType {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUErrorType) ErrorType {
        return @enumFromInt(value);
    }
};

/// WebGPU features that can be requested
pub const FeatureName = enum(u32) {
    // Core features
    depth_clip_control = 0x00000002,
    depth32_float_stencil8 = 0x00000003,
    timestamp_query = 0x00000009,
    indirect_first_instance = 0x0000000A,
    shader_f16 = 0x0000000B,
    rg11b10_ufloat_renderable = 0x0000000C,
    bgra8_unorm_storage = 0x0000000D,
    float32_filterable = 0x0000000E,

    // Texture compression
    texture_compression_bc = 0x00000004,
    texture_compression_etc2 = 0x00000006,
    texture_compression_astc = 0x00000007,

    // Dawn-specific features
    dawn_internal_usages = 0x00050000,
    dawn_multi_planar_formats = 0x00050001,
    dawn_native = 0x00050002,

    // Unknown/unsupported features
    unknown = 0xFFFFFFFF,
    _,

    pub fn toRaw(self: FeatureName) raw.WGPUFeatureName {
        return @intFromEnum(self);
    }

    pub fn fromRaw(value: raw.WGPUFeatureName) FeatureName {
        return @enumFromInt(value);
    }
};
