# Automated Version Updates

This repository includes automated workflows for keeping dependencies up-to-date.

## Rust and Bun Version Updates

The `.github/workflows/update-versions.yml` workflow automatically updates Rust and Bun versions in `docker-bake.hcl`.

### Schedule

- **Runs**: Daily at 2 AM PST (10 AM UTC)
- **Can be triggered manually**: Via GitHub Actions UI

### How It Works

1. **Version Detection**
   - Queries the latest stable Rust version from the official Rust stable channel
   - Queries the latest stable Bun release from GitHub (excludes pre-releases)
   
2. **Change Detection**
   - Compares fetched versions with current versions in `docker-bake.hcl`
   - Only proceeds if a version change is detected

3. **Update Process**
   - Updates `RUST_VERSION` and/or `BUN_VERSION` in `docker-bake.hcl`
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

1. Add a new step to fetch the latest version
2. Add version extraction from `docker-bake.hcl`
3. Add comparison logic
4. Add update logic with sed/awk
5. Update commit message and PR body logic

## Chisel Slice Updates

See the existing `.github/workflows/sync-chisel.yml` for automatic chisel slice synchronization.
