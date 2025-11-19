# Testing the Update Versions Workflow

This guide explains how to test the automated version update workflow to ensure it works correctly.

## Testing Methods

### 1. Local Testing Script

The `test-update-versions.sh` script validates the core workflow logic locally without requiring GitHub Actions.

#### Running the Script

```bash
./test-update-versions.sh
```

#### What It Tests

- ✓ Fetches latest Rust version from official stable channel
- ✓ Fetches latest Bun version from GitHub API
- ✓ Extracts current versions from docker-bake.hcl
- ✓ Tests version update logic with sed commands
- ✓ Validates version comparison logic
- ✓ Checks YAML syntax of workflow files
- ✓ Verifies no cross-contamination between version updates

#### Expected Output

```
=========================================
Update Versions Workflow Test Suite
=========================================

[INFO] Test 1: Fetching latest Rust version...
✓ Fetched Rust version: X.XX.X

[INFO] Test 2: Fetching latest Bun version...
✓ Fetched Bun version: X.X.X

[INFO] Test 3: Extracting versions from docker-bake.hcl...
✓ Extracted current Rust version: X.XX.X
✓ Extracted current Bun version: X.X.X

...

=========================================
Test Summary
=========================================
Passed: 10
Failed: 0

All tests passed!
```

### 2. GitHub Actions Dry-Run Test

The `test-update-versions.yml` workflow allows you to test the update process in GitHub Actions without creating a PR.

#### Running the Test Workflow

1. Go to **Actions** tab in GitHub
2. Select **"Test Update Versions (Dry Run)"** workflow
3. Click **"Run workflow"**
4. Configure options:
   - **test_rust_version**: Leave empty to fetch latest, or specify a version (e.g., `1.92.0`)
   - **test_bun_version**: Leave empty to fetch latest, or specify a version (e.g., `1.4.0`)
   - **skip_pr_creation**: Keep checked for dry-run mode
5. Click **"Run workflow"**

#### What It Does

- Fetches latest versions (or uses provided test versions)
- Compares with current versions in docker-bake.hcl
- Shows what changes would be made (without actually making them)
- Provides a detailed summary of the test run

#### Expected Output

The workflow will show:
- Current versions in docker-bake.hcl
- Latest available versions
- Whether updates are needed
- A diff showing what would change
- Summary confirming the workflow logic is working

### 3. Manual Workflow Trigger (Production Test)

To test the actual workflow end-to-end (including PR creation):

1. Go to **Actions** tab
2. Select **"Update Rust and Bun Versions"** workflow
3. Click **"Run workflow"** and confirm
4. Monitor the workflow execution
5. Check if a PR is created (if versions differ)

**⚠️ Warning**: This creates a real PR if updates are available!

### 4. Testing Auto-Merge Behavior

To verify auto-merge works correctly:

1. Manually trigger the update workflow (if updates are available)
2. Wait for the PR to be created
3. Check that the PR has auto-merge enabled
4. Monitor the build workflow on the PR
5. Confirm the PR auto-merges when CI passes

### 5. Testing with Specific Versions

You can test with specific version numbers using the dry-run workflow:

```yaml
# Example: Test updating to specific versions
test_rust_version: "1.92.0"
test_bun_version: "1.4.0"
skip_pr_creation: true  # Dry-run mode
```

This is useful for:
- Testing version format parsing
- Validating sed commands work with different versions
- Simulating future updates

## Continuous Validation

### Automated Testing

The local test script can be run in CI to validate the workflow logic:

```yaml
- name: Test update-versions logic
  run: ./test-update-versions.sh
```

### Pre-Deployment Validation

Before deploying changes to the workflow:

1. Run `./test-update-versions.sh` locally
2. Validate YAML syntax: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/update-versions.yml'))"`
3. Review the workflow file for any syntax errors
4. Test with the dry-run workflow in GitHub Actions

## Troubleshooting

### Test Script Fails

- **Rust version fetch fails**: Check internet connectivity and Rust API availability
- **Bun version fetch fails**: May be rate-limited or in sandboxed environment (script uses fallback)
- **Version extraction fails**: Verify docker-bake.hcl format hasn't changed
- **Update logic fails**: Check sed commands are compatible with your system

### Workflow Fails

- **Version fetch fails**: Check API availability and authentication
- **PR creation fails**: Verify permissions (contents: write, pull-requests: write)
- **Auto-merge fails**: Ensure repository settings allow auto-merge and all required checks exist

### Auto-Merge Doesn't Trigger

- Verify auto-merge is enabled in repository settings
- Check that required status checks are configured
- Ensure the build workflow runs on pull_request events
- Verify the PR is from the correct branch (bot/rust-bun-bump)

## Best Practices

1. **Run local tests first**: Always run `./test-update-versions.sh` before making workflow changes
2. **Use dry-run mode**: Test with `test-update-versions.yml` before relying on the production workflow
3. **Monitor first run**: Watch the first scheduled run carefully to catch any issues
4. **Check logs**: Review workflow logs for any warnings or errors
5. **Validate PRs**: Manually review the first few auto-generated PRs to ensure quality

## Testing Checklist

Before considering the workflow production-ready:

- [ ] Local test script passes all tests
- [ ] Dry-run workflow executes successfully
- [ ] Version fetching works for both Rust and Bun
- [ ] Version parsing handles current format correctly
- [ ] sed updates work without breaking docker-bake.hcl
- [ ] PR creation works (or would work in production mode)
- [ ] Auto-merge is properly configured
- [ ] Build workflow triggers on PRs
- [ ] Build workflow completes successfully on test PR
- [ ] Auto-merge triggers after successful build

## Next Steps

Once all tests pass:

1. Wait for the first scheduled run (2 AM PST)
2. Monitor for PR creation if updates are available
3. Verify auto-merge behavior
4. Check that images are built and pushed after merge
5. Validate new images work correctly with updated versions
