const std = @import("std");
const dawn = @import("dawn/dawn.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n🎨 Dawn WebGPU Example - GPU Enumeration & Selection\n", .{});
    std.debug.print("====================================================\n\n", .{});

    // Step 1: Initialize WebGPU instance
    std.debug.print("1. Initializing WebGPU instance...\n", .{});
    const instance = try dawn.Instance.init(null);
    defer instance.deinit();
    std.debug.print("   ✓ Instance created successfully\n\n", .{});

    // Step 2: Request the default adapter
    std.debug.print("2. Requesting default GPU adapter...\n", .{});
    const adapter = try instance.requestAdapter(.{
        .power_preference = .high_performance,
    });
    defer adapter.deinit();
    std.debug.print("   ✓ Adapter acquired\n\n", .{});

    // Step 3: Get detailed adapter information
    std.debug.print("3. Querying adapter information...\n", .{});
    const adapter_info = try adapter.getInfo();
    defer adapter_info.deinit();

    // Print beautiful adapter info
    adapter_info.print();

    // Step 4: Enumerate supported features
    std.debug.print("4. Enumerating supported features...\n", .{});
    const features = try adapter.enumerateFeatures(allocator);
    defer allocator.free(features);

    if (features.len > 0) {
        std.debug.print("   Supported features ({d}):\n", .{features.len});
        for (features, 0..) |feature, i| {
            switch (feature) {
                .depth_clip_control,
                .depth32_float_stencil8,
                .timestamp_query,
                .indirect_first_instance,
                .shader_f16,
                .rg11b10_ufloat_renderable,
                .bgra8_unorm_storage,
                .float32_filterable,
                .texture_compression_bc,
                .texture_compression_etc2,
                .texture_compression_astc,
                .dawn_internal_usages,
                .dawn_multi_planar_formats,
                .dawn_native,
                => {
                    std.debug.print("     [{d:2}] {s}\n", .{ i + 1, @tagName(feature) });
                },
                .unknown => {
                    std.debug.print("     [{d:2}] unknown\n", .{i + 1});
                },
                _ => {
                    std.debug.print("     [{d:2}] unknown_feature_0x{X:0>8}\n", .{ i + 1, @intFromEnum(feature) });
                },
            }
        }
    } else {
        std.debug.print("   No additional features reported\n", .{});
    }
    std.debug.print("\n", .{});

    // Step 5: Check for specific features
    std.debug.print("5. Checking for common features...\n", .{});
    const checks = .{
        .{ "Timestamp Queries", dawn.FeatureName.timestamp_query },
        .{ "Depth Clip Control", dawn.FeatureName.depth_clip_control },
        .{ "BC Texture Compression", dawn.FeatureName.texture_compression_bc },
        .{ "Float32 Filterable", dawn.FeatureName.float32_filterable },
    };

    inline for (checks) |check| {
        const has_feature = adapter.hasFeature(check[1]);
        const status = if (has_feature) "✓" else "✗";
        std.debug.print("   {s} {s}\n", .{ status, check[0] });
    }
    std.debug.print("\n", .{});

    // Step 6: Request a device
    std.debug.print("6. Requesting GPU device...\n", .{});
    const device = try adapter.requestDevice(null);
    defer device.deinit();
    std.debug.print("   ✓ Device created successfully\n\n", .{});

    // Step 7: Get the command queue
    std.debug.print("7. Getting command queue...\n", .{});
    const queue = device.getQueue();
    defer queue.deinit();
    std.debug.print("   ✓ Queue acquired\n\n", .{});

    // Done!
    std.debug.print("✨ Success! WebGPU is ready to use.\n", .{});
    std.debug.print("   Backend: {s}\n", .{adapter_info.backend_type.name()});
    std.debug.print("   Device: {s}\n", .{adapter_info.device});
    std.debug.print("\n", .{});
}
