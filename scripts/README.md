# Version Management Scripts

This directory contains reusable shell scripts for managing Rust and Bun versions in `docker-bake.hcl`. These scripts are used by both the production workflows and test scripts to ensure consistency.

## Scripts

### `get-rust-version.sh`
Fetches the latest stable Rust version from the official Rust toolchain channel.

**Usage:**
```bash
./scripts/get-rust-version.sh
```

**Output:** Version string (e.g., `1.91.1`)

### `get-bun-version.sh`
Fetches the latest stable Bun version from GitHub releases API, excluding pre-releases and drafts.

**Usage:**
```bash
# Without authentication
./scripts/get-bun-version.sh

# With authentication (to avoid rate limiting)
GITHUB_TOKEN=your_token ./scripts/get-bun-version.sh
```

**Output:** Version string (e.g., `1.4.0`)

### `get-current-rust-version.sh`
Extracts the current RUST_VERSION from `docker-bake.hcl`.

**Usage:**
```bash
# Default: reads from ./docker-bake.hcl
./scripts/get-current-rust-version.sh

# Custom file
./scripts/get-current-rust-version.sh /path/to/docker-bake.hcl
```

**Output:** Version string (e.g., `1.91.0`)

### `get-current-bun-version.sh`
Extracts the current BUN_VERSION from `docker-bake.hcl`.

**Usage:**
```bash
# Default: reads from ./docker-bake.hcl
./scripts/get-current-bun-version.sh

# Custom file
./scripts/get-current-bun-version.sh /path/to/docker-bake.hcl
```

**Output:** Version string (e.g., `1.3.1`)

### `update-rust-version.sh`
Updates the RUST_VERSION in `docker-bake.hcl`.

**Usage:**
```bash
# Default: updates ./docker-bake.hcl
./scripts/update-rust-version.sh 1.92.0

# Custom file
./scripts/update-rust-version.sh 1.92.0 /path/to/docker-bake.hcl
```

**Effect:** Updates the `default` value in the `RUST_VERSION` variable block

### `update-bun-version.sh`
Updates the BUN_VERSION in `docker-bake.hcl`.

**Usage:**
```bash
# Default: updates ./docker-bake.hcl
./scripts/update-bun-version.sh 1.4.0

# Custom file
./scripts/update-bun-version.sh 1.4.0 /path/to/docker-bake.hcl
```

**Effect:** Updates the `default` value in the `BUN_VERSION` variable block

### `update-readme-rust-version.sh`
Updates the Rust version in `README.md` documentation.

**Usage:**
```bash
# Default: updates ./README.md
./scripts/update-readme-rust-version.sh 1.92.0

# Custom file
./scripts/update-readme-rust-version.sh 1.92.0 /path/to/README.md
```

**Effect:** Updates all Rust Version fields in the README

### `update-readme-bun-version.sh`
Updates the Bun version in `README.md` documentation.

**Usage:**
```bash
# Default: updates ./README.md
./scripts/update-readme-bun-version.sh 1.4.0

# Custom file
./scripts/update-readme-bun-version.sh 1.4.0 /path/to/README.md
```

**Effect:** Updates all Bun Version fields in the README

## Design Principles

1. **Single Responsibility:** Each script does one thing well
2. **Reusability:** Used by workflows, tests, and can be used manually
3. **Testability:** Small, focused scripts are easy to test
4. **Consistency:** Same logic runs in production and tests
5. **Maintainability:** Change once, works everywhere

## Used By

- `.github/workflows/update-versions.yml` - Production update workflow
- `.github/workflows/test-update-versions.yml` - Dry-run test workflow
- `test-update-versions.sh` - Local test script
- Can be used manually for ad-hoc version management

## Adding New Version Scripts

To add support for a new tool version (e.g., NODE_VERSION):

1. Create `get-node-version.sh` to fetch latest version
2. Create `get-current-node-version.sh` to extract current version
3. Create `update-node-version.sh` to update the version
4. Update workflows to use the new scripts
5. Update test script to validate the new scripts
