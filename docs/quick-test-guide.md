# Quick Start: Testing the Update Versions Workflow

## Quick Test (Local)

Run this single command to test everything locally:

```bash
./test-update-versions.sh
```

**Expected Result**: All tests pass (10/10) ✓

## What Gets Tested

### Local Script Tests

1. ✓ Fetches latest Rust version from https://static.rust-lang.org
2. ✓ Fetches latest Bun version from GitHub API
3. ✓ Extracts current versions from docker-bake.hcl
4. ✓ Tests version update sed commands
5. ✓ Validates version comparison logic
6. ✓ Checks YAML syntax
7. ✓ Ensures no cross-contamination between updates

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

## End-to-End Testing

To test the full workflow including PR creation:

1. Go to **Actions** → **"Update Rust and Bun Versions"**
2. Click **"Run workflow"**
3. Monitor for PR creation (if updates are available)

**⚠️ Warning**: This creates a real PR if updates are available!

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
