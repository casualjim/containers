# Quick Start: Testing the Update Versions Workflow

## Quick Test (Local)

Run this single command to test everything locally:

```bash
./test-update-versions.sh
```

**Expected Result**: All tests pass (10/10) ✓

## Quick Test (GitHub Actions)

1. Go to **Actions** tab → **"Test Update Versions (Dry Run)"**
2. Click **"Run workflow"**
3. Keep default settings and click **"Run workflow"** again

**Expected Result**: Workflow completes successfully showing what updates would be made

## What Gets Tested

### Local Script Tests

1. ✓ Fetches latest Rust version from https://static.rust-lang.org
2. ✓ Fetches latest Bun version from GitHub API
3. ✓ Extracts current versions from docker-bake.hcl
4. ✓ Tests version update sed commands
5. ✓ Validates version comparison logic
6. ✓ Checks YAML syntax
7. ✓ Ensures no cross-contamination between updates

### Dry-Run Workflow Tests

1. ✓ Version fetching in GitHub Actions environment
2. ✓ Version comparison logic
3. ✓ Update simulation (shows diff)
4. ✓ Complete workflow execution without side effects

## Interpreting Results

### If Updates Are Available

The test will show:
```
✓ Rust version update needed: 1.91.0 -> 1.91.1
✓ Bun version update needed: 1.3.1 -> 1.4.0
```

This means the production workflow would create a PR.

### If No Updates Available

The test will show:
```
✓ Rust version is up to date: 1.91.1
✓ Bun version is up to date: 1.4.0
```

This means no PR would be created.

## Testing Specific Versions

To test with custom versions:

1. Go to **Actions** → **"Test Update Versions (Dry Run)"**
2. Enter test versions:
   - `test_rust_version`: `1.92.0`
   - `test_bun_version`: `1.5.0`
3. Run workflow

This simulates what would happen if those versions were released.

## Common Issues

| Issue | Solution |
|-------|----------|
| Local script can't fetch Bun version | Normal in sandboxed environments; uses fallback |
| YAML validation fails | Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/update-versions.yml'))"` |
| Version extraction fails | Check docker-bake.hcl format hasn't changed |

## Next Steps

Once tests pass:

1. ✓ Workflow is ready for production use
2. ✓ Will run automatically nightly at 2 AM PST
3. ✓ Can be triggered manually anytime via workflow_dispatch
4. ✓ PRs will auto-merge when CI passes

## Full Documentation

For detailed testing instructions, see [docs/testing-update-workflow.md](testing-update-workflow.md)
