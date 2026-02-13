---
name: add-chisel-slice
description: Use when adding new chisel slices, custom Ubuntu package slices, extending chisel support, or a container needs a package not in upstream chisel-releases
---

# Add Chisel Slice

## Overview

A **rigid** 7-step process for adding custom chisel slice definitions for Ubuntu packages not in upstream chisel-releases.

**Core principle:** Follow every step. No skipping. Each step catches errors the previous step can't.

**IMPORTANT:** All `apt` and `dpkg` commands must run inside an Ubuntu container:
```bash
docker run --rm -it ubuntu:25.10 bash
```

## Checklist (Mandatory)

Complete these in order. Use TodoWrite to track progress.

1. **Identify the package** — Find which Ubuntu package provides what you need
2. **Analyze package contents** — List all files the package installs
3. **Identify dependencies** — Find required packages not in upstream
4. **Create slice definitions** — Write YAML files for package and missing dependencies
5. **Update sync script** — Add packages to `CUSTOM_PACKAGES` in `sync-chisel-slices.sh`
6. **Sync and test** — Run sync script, then build with `docker buildx bake`
7. **Add bake target** — Create target in `docker-bake.hcl` if new image variant needed

## Process

### Step 1: Identify the Package

```bash
# Inside Ubuntu container
apt-get update
apt-cache search <keyword>
apt-cache show <package-name>
```

### Step 2: Analyze Package Contents

```bash
apt-get download <package-name>
dpkg --contents <package-name>*.deb
```

**Critical:** Note both actual files AND symlinks. You need both in your slice.

### Step 3: Identify Dependencies

```bash
apt-cache depends <package-name>
```

For each dependency, check if it exists in upstream:
```bash
ls chisel-releases/slices/ | grep <dependency>
```

If missing, you'll create slices for those too.

### Step 4: Create Slice Definitions

Create YAML in `chisel-releases/slices/<package>.yaml`:

```yaml
package: <package-name>

essential:
  - <package-name>_copyright

slices:
  libs:
    essential:
      - <dependency-package>_libs
      - libc6_libs
    contents:
      /usr/lib/llvm-20/lib/libfoo.so.1.0:
      /usr/lib/*-linux-gnu/libfoo.so.1.0:

  copyright:
    contents:
      /usr/share/doc/<package-name>/copyright:
```

**Key patterns:**
- `*` matches any characters in path
- Use actual versioned filenames (`.so.1.0.20`), not unversioned symlinks
- Always include the copyright slice

### Step 5: Update Sync Script

Edit `sync-chisel-slices.sh`:

```bash
CUSTOM_PACKAGES=(
  # ... existing ...
  "your-new-package"
  "your-dependency-package"
)
```

**Do NOT skip this step.** Without it, your slices get deleted on next upstream sync.

### Step 6: Sync and Test

```bash
./sync-chisel-slices.sh
docker buildx bake <target> --no-cache
```

Watch for errors:
- `cannot extract from package` → File paths don't match (Step 2 error)
- `package not found` → Wrong package name (Step 1 error)
- `slice not found` → Missing dependency slice (Step 3/4 error)

### Step 7: Add Bake Target

Only needed for new image variants. Edit `docker-bake.hcl`:

```hcl
target "my-target" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "my-package_libs"
  }
  tags = ["${REGISTRY}/my-image:latest"]
}
```

## Red Flags - STOP

- Creating slice without running `dpkg --contents`
- Skipping dependency analysis
- Not updating sync script
- Declaring done without `docker buildx bake`
- "The file paths look right" without verification

**All of these mean: Go back to the checklist. Complete the missing step.**

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Identify | `apt-cache search/show` | Find the right package |
| Analyze | `dpkg --contents *.deb` | List exact file paths |
| Dependencies | `apt-cache depends` | Find what else you need |
| Create | Write YAML in slices/ | Define what to extract |
| Sync script | Edit `sync-chisel-slices.sh` | Preserve custom slices |
| Test | `./sync-chisel-slices.sh && docker buildx bake` | Verify it works |
| Bake target | Edit `docker-bake.hcl` | Make it usable |

## Common Mistakes

| Error | Cause | Fix |
|-------|-------|-----|
| `cannot extract from package` | Paths don't match package | Re-run `dpkg --contents`, fix YAML |
| `slice not found` | Missing dependency slice | Create slice for dependency |
| Build succeeds, files missing | Slice not in EXTRA_PACKAGES | Add to bake target args |
| Slices disappear on sync | Not in CUSTOM_PACKAGES | Update sync script |
| Image too large | Including unnecessary files | Review contents, be minimal |

## Deep Reference

For detailed examples and troubleshooting, see `docs/adding-custom-slices.md`.

## Example: libc++ Slices

Created 4 files for LLVM C++ standard library support:

1. `libc++1-20.yaml` — Main library
2. `libc++abi1-20.yaml` — ABI support
3. `libunwind-20.yaml` — Stack unwinding
4. `libc++1.yaml` — Meta-package for convenience

Each follows the pattern: package name, essential copyright, libs slice with dependencies and file paths.

Result: 14.8MB minimal image with libc++ support.
