const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Set up Dawn dependency and module
    const dawn_dep = b.dependency("dawn", .{});
    setupDawnDLLs(b, dawn_dep);
    const dawn_module = createDawnModule(b, dawn_dep, target, optimize);

    // Create main executable
    const exe = createMainExecutable(b, target, optimize, dawn_module);
    b.installArtifact(exe);
    setupRunStep(b, exe);

    // Create Dawn test executable
    const test_exe = createDawnTestExecutable(b, target, optimize, dawn_module);
    b.installArtifact(test_exe);
    setupTestStep(b, test_exe);

    // Add fetch step for DLLs
    setupFetchStep(b);
}

// ============================================================================
// Dawn Module Setup
// ============================================================================

fn setupDawnDLLs(b: *std.Build, dawn_dep: *std.Build.Dependency) void {
    const dlls = [_]struct { src: []const u8, dst: []const u8 }{
        .{ .src = "windows-x64/bin/webgpu_dawn.dll", .dst = "bin/webgpu_dawn.dll" },
        .{ .src = "windows-x64/bin/dxcompiler.dll", .dst = "bin/dxcompiler.dll" },
        .{ .src = "windows-x64/bin/dxil.dll", .dst = "bin/dxil.dll" },
        .{ .src = "windows-x64/bin/d3dcompiler_47.dll", .dst = "bin/d3dcompiler_47.dll" },
    };

    for (dlls) |dll| {
        const install_dll = b.addInstallFile(dawn_dep.path(dll.src), dll.dst);
        b.getInstallStep().dependOn(&install_dll.step);
    }
}

fn createDawnModule(
    b: *std.Build,
    dawn_dep: *std.Build.Dependency,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    const dawn_module = b.createModule(.{
        .root_source_file = b.path("src/dawn/dawn.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add include path for webgpu.h
    dawn_module.addIncludePath(dawn_dep.path("windows-x64/include"));
    
    // Link the library to the module itself
    dawn_module.addLibraryPath(dawn_dep.path("windows-x64/lib"));
    dawn_module.linkSystemLibrary("webgpu_dawn", .{});
    dawn_module.link_libc = true;

    return dawn_module;
}

// ============================================================================
// Main Executable
// ============================================================================

fn createMainExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    dawn_module: *std.Build.Module,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "dawn-test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add Dawn module
    exe.root_module.addImport("dawn", dawn_module);
    
    // Add include path for webgpu.h (needed for @cImport in dawn module)
    const dawn_dep = b.dependency("dawn", .{});
    exe.root_module.addIncludePath(dawn_dep.path("windows-x64/include"));
    
    exe.linkLibC();
    return exe;
}

fn setupRunStep(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.cwd = b.path("zig-out/bin");

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the main application");
    run_step.dependOn(&run_cmd.step);
}

// ============================================================================
// Dawn Test Executable
// ============================================================================

fn createDawnTestExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    dawn_module: *std.Build.Module,
) *std.Build.Step.Compile {
    const test_exe = b.addExecutable(.{
        .name = "test-dawn",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/dawn/test_dawn.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Import the dawn module
    test_exe.root_module.addImport("dawn", dawn_module);
    
    // Add include path for webgpu.h (needed for @cImport in dawn module)
    const dawn_dep = b.dependency("dawn", .{});
    test_exe.root_module.addIncludePath(dawn_dep.path("windows-x64/include"));
    
    test_exe.linkLibC();

    return test_exe;
}

fn setupTestStep(b: *std.Build, test_exe: *std.Build.Step.Compile) void {
    const test_cmd = b.addRunArtifact(test_exe);
    test_cmd.cwd = b.path("zig-out/bin");

    const test_step = b.step("test", "Run Dawn DLL linkage test");
    test_step.dependOn(&test_cmd.step);
}

// ============================================================================
// Utility Steps
// ============================================================================

fn setupFetchStep(b: *std.Build) void {
    const fetch_step = b.step("fetch", "Fetch and install Dawn DLLs");
    fetch_step.dependOn(b.getInstallStep());
}
