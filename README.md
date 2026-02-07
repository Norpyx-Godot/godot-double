# godot-double-ops

Automation hub for the Godot double-precision AUR packages. This repo keeps the
`godot-double` and `godot-double-bin` packages as submodules and provides a
single entry script to run the full release flow end-to-end.

## Layout

- `godot-double/`: source build AUR repo (submodule).
- `godot-double-bin/`: binary AUR repo (submodule, generated from releases).
- `dist/`: release artifacts copied from the source build.
- `bin/gdops`: entry script with subcommands.
- `scripts/`: implementation for each step.

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

1. Check the latest Godot upstream release manually.
2. Update `godot-double/PKGBUILD`:
   ```bash
   ./bin/gdops bump 4.5.1 0
   ./bin/gdops pull
   ```
3. Build the source package:
   ```bash
   ./bin/gdops build
   ```
4. Generate the binary package metadata:
   ```bash
   ./bin/gdops hydrate
   ```
5. Create the GitHub release:
   ```bash
   ./bin/gdops release
   ```
6. Commit and push AUR updates:
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

## Notes

- `hydrate` expects a built `*.pkg.tar.zst` in `godot-double/` and copies it into
  `dist/` before generating `godot-double-bin/PKGBUILD`.
- `release` uses the `gh` CLI and requires auth to `GH_REPO`.
- `publish` is split into explicit steps; nothing auto-pushes unless you call
  `push` or `all --push`.
- Submodule URLs are relative; update `.gitmodules` if you clone this elsewhere.
