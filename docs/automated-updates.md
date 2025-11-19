# Automated Version Updates

This repository includes automated workflows for keeping dependencies up-to-date.

## Rust and Bun Version Updates

The `.github/workflows/update-versions.yml` workflow automatically updates Rust and Bun versions in `docker-bake.hcl`.

### Schedule

- **Runs**: Daily at 2 AM PST (10 AM UTC)
- **Can be triggered manually**: Via GitHub Actions UI

### How It Works

1. **Version Detection**
   - Uses reusable scripts in `scripts/` directory
   - Queries the latest stable Rust version from the official Rust stable channel
   - Queries the latest stable Bun release from GitHub (excludes pre-releases)
   
2. **Change Detection**
   - Compares fetched versions with current versions in `docker-bake.hcl`
   - Only proceeds if a version change is detected

3. **Update Process**
   - Updates `RUST_VERSION` and/or `BUN_VERSION` in `docker-bake.hcl` using shared scripts
   - Creates or updates a branch named `bot/rust-bun-bump`
   - Commits changes with message: `chore: update Rust/Bun version in docker-bake.hcl`

4. **Pull Request**
   - Creates or updates a PR from `bot/rust-bun-bump` to `main`
   - Includes detailed change information
   - Enables auto-merge (squash merge)

5. **CI Verification**
   - PR triggers the build workflow
   - Builds are tested but not pushed to registry
   - Auto-merge completes when all checks pass

6. **Post-Merge**
   - Build workflow runs again on `main` branch
   - New images are built and pushed with updated versions

### Architecture

The workflow uses reusable shell scripts in the `scripts/` directory:

- `get-rust-version.sh` - Fetches latest Rust version
- `get-bun-version.sh` - Fetches latest Bun version
- `get-current-rust-version.sh` - Extracts current Rust version from docker-bake.hcl
- `get-current-bun-version.sh` - Extracts current Bun version from docker-bake.hcl
- `update-rust-version.sh` - Updates Rust version in docker-bake.hcl
- `update-bun-version.sh` - Updates Bun version in docker-bake.hcl

This ensures the same logic is used by:
- Production workflow (`.github/workflows/update-versions.yml`)
- Test workflow (`.github/workflows/test-update-versions.yml`)
- Local test script (`test-update-versions.sh`)

See `scripts/README.md` for detailed script documentation.

### Manual Intervention

No manual intervention is required. However, you can:

- **Disable auto-merge**: Close the PR or disable auto-merge manually
- **Review changes**: Check the PR before it auto-merges
- **Trigger manually**: Use workflow_dispatch in GitHub Actions

### Version Sources

- **Rust**: https://static.rust-lang.org/dist/channel-rust-stable.toml
- **Bun**: https://api.github.com/repos/oven-sh/bun/releases

### Extending

To add more tools to auto-update:

1. Create three new scripts in `scripts/` directory:
   - `get-{tool}-version.sh` - Fetch latest version from upstream
   - `get-current-{tool}-version.sh` - Extract current version from docker-bake.hcl
   - `update-{tool}-version.sh` - Update version in docker-bake.hcl
2. Update workflows to use the new scripts
3. Add comparison and PR body logic
4. Update test script to validate the new scripts

See `scripts/README.md` for examples and best practices.

### Testing

The workflow can be tested in multiple ways:

- **Local testing**: Run `./test-update-versions.sh` to validate core logic
- **Dry-run testing**: Use the "Test Update Versions (Dry Run)" workflow in GitHub Actions
- **Manual trigger**: Use workflow_dispatch to test end-to-end

See [Testing the Update Workflow](testing-update-workflow.md) for detailed testing instructions.

## Chisel Slice Updates

See the existing `.github/workflows/sync-chisel.yml` for automatic chisel slice synchronization.
