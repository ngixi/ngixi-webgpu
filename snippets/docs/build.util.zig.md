# build.util.zig

A build utility designed to let you specify dependencies for specific platform targets and validate them before the build starts. Blocks the build if required dependencies for the target platform are missing.

## Features

- ✅ **Target-specific dependencies** - Define different dependencies for Windows, Linux, macOS, etc.
- ✅ **Pre-build validation** - Checks dependencies before build starts, not halfway through
- ✅ **Optional dependencies** - Mark dependencies as required or optional per platform
- ✅ **Platform name resolution** - Automatically resolves `dawn` → `dawn_windows_x86_64` based on target
- ✅ **Clear feedback** - See which dependencies are satisfied, missing, or skipped

## Installation

Add as a git subtree to your project:

```bash
git subtree add --prefix=snippets git@github.com:mannsion/zig-snippets.git main --squash
```

## Usage

**1. Import in your `build.zig`:**

```zig
const std = @import("std");
const util = @import("snippets/build.util.zig");
const build_manifest = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    // Define dependency requirements
    const dependency_specs = [_]util.DependencySpec{
        .{
            .name = "dawn",
            .is_target_specific = true,  // Resolves to dawn_windows_x86_64, etc.
            .skippable = false,           // Required for build
        },
        .{
            .name = "zigwin32",
            .is_target_specific = false,  // Same name on all platforms
            .skippable = true,            // Optional dependency
            .required_os = &[_]std.Target.Os.Tag{.windows}, // Windows only
        },
    };

    // Check all dependencies
    const dep_summary = util.checkDependencies(b, build_manifest, target.result, &dependency_specs);

    // Show results
    dep_summary.printSummary();

    // Exit if required dependencies are missing
    if (!dep_summary.allSatisfied()) {
        std.debug.print("💥 Build cannot continue - required dependencies missing!\n", .{});
        std.process.exit(1);
    }

    // Use satisfied dependencies
    for (dep_summary.results) |result| {
        if (std.mem.eql(u8, result.name, "dawn") and result.status == .satisfied) {
            const dawn_dep = result.dependency.?;
            // Use the dependency...
        }
    }
}
```

**2. Configure dependencies in `build.zig.zon`:**

```zig
.dependencies = .{
    .dawn_windows_x86_64 = .{
        .url = "https://github.com/ngixi/ngixi-builds/releases/download/dawn-v1.0.0/dawn-windows-x86_64.tar.gz",
        .hash = "...",
        .lazy = true,  // Only fetch when needed
    },
    .zigwin32 = .{
        .url = "https://github.com/marlersoft/zigwin32/archive/refs/tags/v0.15.1.tar.gz",
        .hash = "...",
        .lazy = true,
    },
},
```

## Example Output

**All dependencies satisfied:**

```
📊 Dependency Check Summary:
   Total: 2 | ✅ Satisfied: 2 | ⏭️ Skipped: 0 | ❌ Missing: 0
   ✅ dawn → dawn_windows_x86_64
   ✅ zigwin32 → zigwin32
```

**Platform-specific dependency skipped:**

```
📊 Dependency Check Summary:
   Total: 2 | ✅ Satisfied: 1 | ⏭️ Skipped: 1 | ❌ Missing: 0
   ✅ dawn → dawn_linux_x86_64
   ⏭️ zigwin32 → zigwin32
```

**Missing required dependency:**

```
📊 Dependency Check Summary:
   Total: 2 | ✅ Satisfied: 1 | ⏭️ Skipped: 0 | ❌ Missing: 1
   ✅ zigwin32 → zigwin32
   ❌ dawn → dawn_macos_aarch64

💥 Build cannot continue - required dependencies missing!
```

## API Reference

### Types

**`DependencySpec`** - Defines a dependency requirement

- `name: []const u8` - Base dependency name
- `is_target_specific: bool = false` - If true, appends `_{os}_{arch}` to name
- `skippable: bool = false` - If true, missing dependency won't cause build failure
- `required_os: ?[]const std.Target.Os.Tag = null` - OS tags where dependency is needed

**`DependencyResult`** - Result of dependency check

- `name: []const u8` - Base dependency name
- `resolved_name: []const u8` - Actual dependency name used
- `status: Status` - `.satisfied`, `.skipped`, or `.missing`
- `dependency: ?*std.Build.Dependency` - The resolved dependency if satisfied

**`DependencyCheckSummary`** - Summary of all dependency checks

- `results: []DependencyResult` - Array of individual results
- `total_count: usize` - Total dependencies checked
- `satisfied_count: usize` - Successfully resolved dependencies
- `skipped_count: usize` - Skipped optional dependencies
- `missing_count: usize` - Missing required dependencies

### Functions

**`checkDependencies(b, build_manifest, target, specs)`**

- Checks all dependencies and returns a summary
- Parameters:
  - `b: *std.Build` - Build context
  - `build_manifest: anytype` - Your `build.zig.zon` import
  - `target: std.Target` - Target platform
  - `specs: []const DependencySpec` - Dependency specifications
- Returns: `DependencyCheckSummary`

**`getPlatformDependency(b, dep_prefix, target)`**

- Generates platform-specific dependency name
- Parameters:
  - `b: *std.Build` - Build context
  - `dep_prefix: []const u8` - Base dependency name
  - `target: std.Target` - Target platform
- Returns: `[]const u8` - Formatted name like `dawn_windows_x86_64`

**`printAvailableDependencies(build_manifest)`**

- Prints all dependencies defined in `build.zig.zon` (useful for debugging)
- Parameters:
  - `build_manifest: anytype` - Your `build.zig.zon` import

## Advanced Usage

**Debug available dependencies:**

```zig
pub fn build(b: *std.Build) void {
    // Uncomment to see all available dependencies
    // util.printAvailableDependencies(build_manifest);

    // ... rest of build
}
```

Output:

```
📦 Build Manifest Analysis:
   Package: "ngixi-dawn"
   Version: "0.1.0"
   Dependencies (2):
     ✓ dawn_windows_x86_64
     ✓ zigwin32
```

**Platform-specific logic:**

```zig
const dependency_specs = [_]util.DependencySpec{
    .{
        .name = "opengl",
        .skippable = true,
        .required_os = &[_]std.Target.Os.Tag{.linux, .windows},
    },
    .{
        .name = "metal",
        .skippable = true,
        .required_os = &[_]std.Target.Os.Tag{.macos},
    },
};
```

## Updating

Pull latest changes from the snippet repository:

```bash
git subtree pull --prefix=snippets git@github.com:mannsion/zig-snippets.git main --squash
```

Push your improvements back:

```bash
git subtree push --prefix=snippets git@github.com:mannsion/zig-snippets.git main
```
