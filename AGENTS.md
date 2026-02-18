# Repository Guidelines

## Project Structure & Module Organization
This repo builds container images with Docker Bake.
- Root Dockerfiles: `Dockerfile`, `Dockerfile.openbao`, `Dockerfile.netdebug`, `Dockerfile.rustbuilder`, `Dockerfile.sqlx`.
- Build matrix and tags: `docker-bake.hcl` (single source of truth for targets and args).
- Automation scripts: `scripts/` (version fetch/update helpers).
- Chisel package slices: `chisel-releases/`.
- Post-install hooks for image customization: `post-install/`.
- CI/CD workflows: `.forgejo/workflows/`.
- Docs and runbooks: `docs/`.

## Build, Test, and Development Commands
- `docker buildx bake`  
  Build default target group.
- `docker buildx bake <target>`  
  Build one image target (example: `docker buildx bake openbao`).
- `docker buildx bake --print openbao`  
  Validate resolved build config without building.
- `./test-update-versions.sh`  
  Run local checks for update workflow logic and script behavior.
- `./sync-chisel-slices.sh`  
  Sync custom slice set from upstream chisel-releases.

## Coding Style & Naming Conventions
- Use Bash with `set -euo pipefail` for scripts.
- Keep YAML/HCL formatting consistent with existing files (2-space indentation).
- Script filenames use kebab-case (for actions) or `get-/update-` patterns in `scripts/`.
- Keep Docker Bake target/variable names explicit and uppercase for shared args (example: `OPENBAO_VERSION`).

## Testing Guidelines
- For build changes, run at least:
  - `docker buildx bake --print <changed-target>`
  - `./test-update-versions.sh` when touching `scripts/` or workflow logic.
- Prefer focused verification for changed targets rather than full rebuilds during iteration.

## Commit & Pull Request Guidelines
- Follow Conventional Commits seen in history, e.g.:
  - `fix(ci): propagate OpenBao plugin SHA args in Forgejo build`
  - `feat(netdebug): add kubernetes and service debugging CLIs`
- PRs should include:
  - clear summary,
  - impacted targets/files,
  - validation commands run.
- Merge strategy is defined below.

## Git And PR Merge Policy

- Use merge commits for pull requests.
- Do not squash merge pull requests unless explicitly requested by the user.
