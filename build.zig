const std = @import("std");
const util = @import("build.util.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 📋 Uncomment to see available dependencies during build
    // util.printAvailableDependencies();

    // � Define our dependency requirements
    const dependency_specs = [_]util.DependencySpec{
        .{
            .name = "dawn",
            .is_target_specific = true,
            .skippable = false, // Dawn is required for all targets we support
        },
        .{
            .name = "zigwin32",
            .is_target_specific = false,
            .skippable = true, // Only needed on Windows
            .required_os = &[_]std.Target.Os.Tag{.windows},
        },
    };

    // 🛡️ Check all dependencies comprehensively
    const dep_summary = util.checkDependencies(b, target.result, &dependency_specs);

    // 📊 Show dependency check results
    dep_summary.printSummary();

    // 🚨 Exit if any required dependencies are missing
    if (!dep_summary.allSatisfied()) {
        std.debug.print("💥 Build cannot continue - required dependencies missing!\n", .{});
        std.process.exit(1);
    }

    // 🎯 Get the Dawn dependency (we know it exists from the check above)
    var dawn_dep: ?*std.Build.Dependency = null;
    var zigwin32_dep: ?*std.Build.Dependency = null;

    for (dep_summary.results) |result| {
        if (std.mem.eql(u8, result.name, "dawn") and result.status == .satisfied) {
            dawn_dep = result.dependency;
        } else if (std.mem.eql(u8, result.name, "zigwin32") and result.status == .satisfied) {
            zigwin32_dep = result.dependency;
        }
    }

    // Build executable
    const exe = b.addExecutable(.{
        .name = "ngixi-dawn",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Configure Dawn paths (we know dawn_dep exists)
    configureDawnPaths(b, exe, dawn_dep.?, target.result);

    // Add platform-specific dependencies
    if (zigwin32_dep) |zigwin32| {
        exe.root_module.addImport("win32", zigwin32.module("win32"));
    }

    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn configureDawnPaths(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    dawn_dep: *std.Build.Dependency,
    target: std.Target,
) void {
    // Add include and lib paths
    exe.addIncludePath(dawn_dep.path("include"));
    exe.addLibraryPath(dawn_dep.path("lib"));

    // Platform-specific configuration
    switch (target.os.tag) {
        .windows => {
            exe.linkSystemLibrary("webgpu_dawn");

            // Install DLLs
            const dlls = [_][]const u8{ "webgpu_dawn.dll", "d3dcompiler_47.dll", "dxcompiler.dll", "dxil.dll" };
            for (dlls) |dll| {
                const install_dll = b.addInstallBinFile(dawn_dep.path(b.fmt("bin/{s}", .{dll})), dll);
                exe.step.dependOn(&install_dll.step);
            }

            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("gdi32");
        },
        .linux => {
            exe.linkSystemLibrary("webgpu_dawn");
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("pthread");
        },
        .macos => {
            exe.linkSystemLibrary("webgpu_dawn");
            exe.linkFramework("Cocoa");
            exe.linkFramework("QuartzCore");
            exe.linkFramework("Metal");
        },
        else => {},
    }

    exe.linkLibC();
    exe.linkLibCpp();
}
