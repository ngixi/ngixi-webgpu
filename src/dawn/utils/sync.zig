// Utilities for converting async callback-based WebGPU APIs to synchronous error unions
// This makes the API much more ergonomic and Zig-idiomatic

const std = @import("std");
const raw = @import("../raw/c.zig").c;

/// Thread-local storage for adapter request results
threadlocal var adapter_result: ?struct {
    adapter: ?raw.WGPUAdapter,
    status: raw.WGPURequestAdapterStatus,
} = null;

/// Thread-local storage for device request results
threadlocal var device_result: ?struct {
    device: ?raw.WGPUDevice,
    status: raw.WGPURequestDeviceStatus,
} = null;

/// Request an adapter synchronously
/// Blocks until the adapter is ready or the request fails
pub fn requestAdapterSync(
    instance: raw.WGPUInstance,
    options: ?*const raw.WGPURequestAdapterOptions,
) !raw.WGPUAdapter {
    adapter_result = .{
        .adapter = null,
        .status = raw.WGPURequestAdapterStatus_Error,
    };

    const callback_info = raw.WGPURequestAdapterCallbackInfo{
        .mode = raw.WGPUCallbackMode_AllowSpontaneous,
        .callback = adapterCallback,
        .userdata1 = null,
        .userdata2 = null,
        .nextInChain = null,
    };

    const future = raw.wgpuInstanceRequestAdapter(instance, options, callback_info);

    // Wait for the callback to complete
    var future_wait_info = raw.WGPUFutureWaitInfo{
        .future = future,
        .completed = raw.WGPU_FALSE,
    };
    const wait_status = raw.wgpuInstanceWaitAny(instance, 1, &future_wait_info, std.math.maxInt(u64));
    _ = wait_status;

    const result = adapter_result orelse return error.AdapterRequestFailed;

    return switch (result.status) {
        raw.WGPURequestAdapterStatus_Success => result.adapter orelse error.AdapterRequestFailed,
        raw.WGPURequestAdapterStatus_CallbackCancelled => error.AdapterRequestCancelled,
        raw.WGPURequestAdapterStatus_Unavailable => error.AdapterUnavailable,
        raw.WGPURequestAdapterStatus_Error => error.AdapterRequestError,
        else => error.AdapterRequestFailed,
    };
}

/// Callback for adapter requests
fn adapterCallback(
    status: raw.WGPURequestAdapterStatus,
    adapter: raw.WGPUAdapter,
    message: raw.WGPUStringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
) callconv(.c) void {
    _ = message;
    _ = userdata1;
    _ = userdata2;

    adapter_result = .{
        .adapter = adapter,
        .status = status,
    };
}

/// Request a device synchronously
/// Blocks until the device is ready or the request fails
pub fn requestDeviceSync(
    instance: raw.WGPUInstance,
    adapter: raw.WGPUAdapter,
    descriptor: ?*const raw.WGPUDeviceDescriptor,
) !raw.WGPUDevice {
    device_result = .{
        .device = null,
        .status = raw.WGPURequestDeviceStatus_Error,
    };

    const callback_info = raw.WGPURequestDeviceCallbackInfo{
        .mode = raw.WGPUCallbackMode_AllowSpontaneous,
        .callback = deviceCallback,
        .userdata1 = null,
        .userdata2 = null,
        .nextInChain = null,
    };

    const future = raw.wgpuAdapterRequestDevice(adapter, descriptor, callback_info);

    // Wait for the callback to complete
    var future_wait_info = raw.WGPUFutureWaitInfo{
        .future = future,
        .completed = raw.WGPU_FALSE,
    };
    const wait_status = raw.wgpuInstanceWaitAny(instance, 1, &future_wait_info, std.math.maxInt(u64));
    _ = wait_status;

    const result = device_result orelse return error.DeviceRequestFailed;

    return switch (result.status) {
        raw.WGPURequestDeviceStatus_Success => result.device orelse error.DeviceRequestFailed,
        raw.WGPURequestDeviceStatus_CallbackCancelled => error.DeviceRequestCancelled,
        raw.WGPURequestDeviceStatus_Error => error.DeviceRequestError,
        else => error.DeviceRequestFailed,
    };
}

/// Callback for device requests
fn deviceCallback(
    status: raw.WGPURequestDeviceStatus,
    device: raw.WGPUDevice,
    message: raw.WGPUStringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
) callconv(.c) void {
    _ = message;
    _ = userdata1;
    _ = userdata2;

    device_result = .{
        .device = device,
        .status = status,
    };
}
