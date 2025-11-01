# zig-snippets

Helpful Zig Snippets you can add to your repo as a git subtree to reuse in projects.

## 📚 Available Snippets

- **[build.util.zig](docs/build.util.zig.md)** - Specify and validate platform-specific dependencies for your build targets

## Installation

Add as a git subtree to your project:

```bash
git subtree add --prefix=snippets git@github.com:mannsion/zig-snippets.git main --squash
```

## Updating

Pull latest changes:

```bash
git subtree pull --prefix=snippets git@github.com:mannsion/zig-snippets.git main --squash
```

Push your improvements back:

```bash
git subtree push --prefix=snippets git@github.com:mannsion/zig-snippets.git main
```
