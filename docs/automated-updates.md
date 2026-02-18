# Automated Version Updates

This repository includes automated workflows for keeping dependencies up-to-date.

## Automated Version Updates

Version update workflow:
- `.forgejo/workflows/update-versions.yml`

Managed values in `docker-bake.hcl`:
- `RUST_VERSION`
- `BUN_VERSION`
- `OPENBAO_VERSION`
- `OPENBAO_CLOUDFLARE_PLUGIN_VERSION`

### Schedule

- **Runs**: Daily at 2 AM PST (10 AM UTC)
- **Can be triggered manually**: Via `workflow_dispatch` in Forgejo Actions UI

### How It Works

1. **Version Detection**
   - Uses reusable scripts in `scripts/` directory
   - Queries the latest stable Rust version from the official Rust stable channel
   - Queries the latest stable Bun release from GitHub (excludes pre-releases)
   - Queries the latest OpenBao release
   - Queries the latest Cloudflare plugin release
   
2. **Change Detection**
   - Compares fetched versions with current versions in `docker-bake.hcl`
   - Only proceeds if a version change is detected

3. **Update Process**
   - Updates changed values in `docker-bake.hcl` using shared scripts
   - Creates or updates a branch named `bot/version-bump`
   - Commits changes with a generated `chore: update ...` message

4. **Pull Request**
   - Creates or updates a PR from `bot/version-bump` to `main`
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
- `get-openbao-version.sh` - Fetches latest OpenBao version
- `get-cloudflare-plugin-version.sh` - Fetches latest Cloudflare plugin version
- `get-current-rust-version.sh` - Extracts current Rust version from docker-bake.hcl
- `get-current-bun-version.sh` - Extracts current Bun version from docker-bake.hcl
- `get-current-openbao-version.sh` - Extracts current OpenBao version from docker-bake.hcl
- `get-current-cloudflare-plugin-version.sh` - Extracts current Cloudflare plugin version from docker-bake.hcl
- `update-rust-version.sh` - Updates Rust version in docker-bake.hcl
- `update-bun-version.sh` - Updates Bun version in docker-bake.hcl
- `update-openbao-version.sh` - Updates OpenBao version in docker-bake.hcl
- `update-cloudflare-plugin-version.sh` - Updates Cloudflare plugin version in docker-bake.hcl

This ensures the same logic is used by:
- Production workflow (`.forgejo/workflows/update-versions.yml`)
- Local test script (`test-update-versions.sh`) for Rust/Bun checks

See `scripts/README.md` for detailed script documentation.

### Manual Intervention

No manual intervention is required. However, you can:

- **Disable auto-merge**: Close the PR or disable auto-merge manually
- **Review changes**: Check the PR before it auto-merges
- **Trigger manually**: Use `workflow_dispatch`

### Version Sources

- **Rust**: https://static.rust-lang.org/dist/channel-rust-stable.toml
- **Bun**: https://api.github.com/repos/oven-sh/bun/releases
- **OpenBao**: https://api.github.com/repos/openbao/openbao/releases/latest
- **Cloudflare plugin**: https://api.github.com/repos/bloominlabs/vault-plugin-secrets-cloudflare/releases/latest

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
- **Manual trigger**: Use workflow_dispatch to test end-to-end

See [Testing the Update Workflow](testing-update-workflow.md) for detailed testing instructions.

## Chisel Slice Updates

See `.forgejo/workflows/sync-chisel.yml` for automatic chisel slice synchronization.
