# godot-double-ops

Automation hub for the Godot double-precision AUR packages. This repo keeps the
`godot-double` and `godot-double-bin` packages as submodules and provides a
single entry script to run the full release flow end-to-end.

## Layout

- `godot-double/`: source build AUR repo (submodule).
- `godot-double-bin/`: binary AUR repo (submodule, generated from releases).
- `dist/`: release artifacts copied from the source build.
- `docker/`: Docker image and entrypoint for CI-compatible validation.
- `bin/gdops`: entry script with subcommands.
- `scripts/`: implementation for each step.
- `tests/`: lightweight shell tests for the release automation.

## Setup

```bash
git submodule update --init --recursive
```

Optional overrides go in `config.local.sh` (ignored by git). The defaults live
in `config.sh`:

- `GH_REPO`: GitHub repo used for releases (owner/repo).
- `RELEASE_PREFIX`: tag prefix (default `v`).
- `AUR_REMOTE`: remote name for pushing AUR updates.
- `MAKEPKG_ARGS`: arguments passed to `makepkg` when building.

## Typical Release Flow

1. Run the Dockerized update:
   ```bash
   ./bin/gdops update
   ```
2. Review the resolved version, package metadata, and artifacts in `dist/`.
3. Create the GitHub release:
   ```bash
   ./bin/gdops release
   ```
4. Commit and push AUR updates:
   ```bash
   ./bin/gdops commit
   ./bin/gdops push
   ```

You can run the full pipeline in one go:

```bash
./bin/gdops all --push 4.5.1 0
```

Dry-run any step with `--dry-run`:

```bash
./bin/gdops --dry-run hydrate
./bin/gdops all --dry-run 4.5.1 0
```

## Update Pipeline

The maintainer-facing update command runs the Dockerized test-plus-stage flow.
It does not publish GitHub releases, commit changes, or push AUR repositories.

Default update to the latest matching Arch `godot`/`godot-mono` version:

```bash
./bin/gdops update
```

Explicit version update:

```bash
./bin/gdops update 4.5.1 0
```

Local CI gate:

```bash
./bin/gdops ci 4.5.1 0
./bin/gdops ci latest
```

Containerized CI gate:

```bash
./bin/gdops docker ci 4.5.1 0
./bin/gdops docker ci latest
```

Containerized one-shot staging:

```bash
./bin/gdops docker stage 4.5.1 0
./bin/gdops docker stage latest
```

Local bump validation only:

```bash
./bin/gdops validate 4.5.1 0
./bin/gdops validate latest
```

Dockerized bump validation only:

```bash
./bin/gdops docker validate 4.5.1 0
./bin/gdops docker validate latest
```

Dry-run validation:

```bash
./bin/gdops --dry-run update
./bin/gdops --dry-run update 4.5.1 0
./bin/gdops --dry-run ci 4.5.1 0
./bin/gdops --dry-run ci latest
./bin/gdops --dry-run stage 4.5.1 0
./bin/gdops --dry-run stage latest
./bin/gdops --dry-run validate 4.5.1 0
./bin/gdops --dry-run validate latest
./bin/gdops --dry-run docker ci 4.5.1 0
./bin/gdops --dry-run docker ci latest
./bin/gdops --dry-run docker stage 4.5.1 0
./bin/gdops --dry-run docker stage latest
./bin/gdops --dry-run docker validate 4.5.1 0
./bin/gdops --dry-run docker validate latest
```

The official Arch package source is the baseline. Arch currently publishes
`godot` and `godot-mono` from the same `godot` split-package PKGBUILD, so the
sync step fetches that official package source and transforms it locally.

The `ci` command runs the coverage-backed automation tests first, then the same
staging stages used by `stage`:

- `arch-latest`: when using `latest`, resolves the official Arch `godot` and
  `godot-mono` package version through `pacman` and requires them to match.
- `sync-arch-pkgbuild`: fetches the official Arch `godot` package source with
  `pkgctl`, then transforms its split PKGBUILD into `godot-double` and
  `godot-double-mono`.
- `preflight`: checks submodules, metadata files, config, tools, and version
  input shape.
- `bump`: updates `godot-double/PKGBUILD`.
- `source-check`: refreshes checksums and verifies `godot-double/.SRCINFO`.
- `build`: runs `makepkg`.
- `artifact-check`: verifies the expected package artifact exists.
- `hydrate-check`: generates and verifies `godot-double-bin` metadata.

After `update` or `docker stage`, the source package artifacts are built under
`godot-double/`, copied to `dist/`, and `godot-double-bin/PKGBUILD` plus
`.SRCINFO` are regenerated.

Expected package outputs:

- `godot-double`
- `godot-double-mono`
- `godot-double-bin`
- `godot-double-mono-bin`

Release creation and AUR pushes are intentionally separate because they require
external credentials and publish irreversible state.

For debugging the container environment:

```bash
./bin/gdops docker shell
```

The Docker wrapper builds `godot-double-ci:latest` by default, mounts this repo
at `/workspace`, and runs the same `gdops ci` or `gdops validate` command inside
the container. CI systems can call `./bin/gdops docker ci <pkgver> <pkgrel>`
directly after checkout and submodule initialization.

Useful Docker overrides:

- `GDOPS_DOCKER_IMAGE`: image tag to build/run.
- `GDOPS_DOCKER_NO_BUILD=1`: skip image build when CI builds it separately.

## Notes

- `hydrate` expects built `godot-double` and `godot-double-mono` package
  artifacts in `godot-double/`, copies them into `dist/`, and generates the
  split `godot-double-bin` / `godot-double-mono-bin` PKGBUILD.
- `release` uses the `gh` CLI and requires auth to `GH_REPO`.
- `publish` is split into explicit steps; nothing auto-pushes unless you call
  `push` or `all --push`.
- Submodule URLs are relative; update `.gitmodules` if you clone this elsewhere.

## Canonical Commands

- Tests: `./tests/run.sh`
- Coverage: `./tests/coverage.sh`
- Docs build: not applicable; docs are Markdown/workplans only.
