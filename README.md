# ngixi-webgpu

> **🚧 EARLY STAGE 🚧**  
> *Zig wrapper for Google Dawn WebGPU. Currently just C header linkage—Zig API wrapper not started yet.*

## What This Is

A consumable Zig package that wraps Google Dawn WebGPU. The intent is to provide a clean Zig API while tracking upstream Dawn releases.

**Scope**: Pure WebGPU wrapper only—no windowing, no other dependencies. Just Dawn.

## Current Status

**What Works**:
- ✅ Windows builds from ngixi-builds (Dawn DLLs + headers)
- ✅ C header linking via `@cImport` in `raw` module
- ✅ Basic build system setup

**What's Not Started**:
- ❌ Zig API wrapper (still using raw C imports)
- ❌ Linux builds (ngixi-builds doesn't have this yet)
- ❌ macOS builds (ngixi-builds doesn't have this yet)

## Architecture

1. **ngixi-builds** compiles Dawn from Google's upstream tags
2. **ngixi-webgpu** (this repo) fetches those prebuilt binaries
3. Provides C headers via `@cImport` (current)
4. Will provide idiomatic Zig API wrapper (future)

## Quick Start

**Not yet usable as a dependency.** Currently in early development.

```bash
zig build        # Fetch Dawn DLLs, build
zig build run    # Run test (if any)
```

**Requirements**: Zig 0.15.1+

## Release Strategy (Future)

When ready, this package will be released with tags matching the Google Dawn version it was built and tested against.

**Example**: Release `v20251026.130842` → tested against Google Dawn `v20251026.130842`

This allows consumers to pin to specific Dawn versions with confidence.

**Current Status**: Not yet published. No releases available.

## Tracking Upstream

This wrapper tracks Google Dawn releases. When ngixi-builds updates to a new Dawn tag, this package updates accordingly.

**Current Dawn Version**: Check ngixi-builds for the active tag (approximately `v20251026.130842`)

## Status

- **Platform Support**: Windows only (via ngixi-builds)
- **API**: Raw C headers only (no Zig wrapper yet)
- **Upstream**: Tracking Google Dawn stable tags

Part of the [NGIXI](https://github.com/ngixi) ecosystem.

---

**Note**: This is a pure WebGPU wrapper. No windowing, no SDL, no other dependencies. Just Dawn.