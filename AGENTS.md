# Repository Guidelines

This repository contains Arch Linux AUR packaging for Godot double-precision
variants. The main working directory is `godot-double-gh/`, which hosts this
guide; each package directory is self-contained, and its `PKGBUILD` is the
source of truth for build steps and install layout.

## Project Structure & Module Organization

- `godot-double/`: source-built double-precision package (includes Mono subpackage).
- `godot-double-bin/`: binary package variant.
- `godot-double-gh/`: GitHub release variant and primary working directory.
- `godot-double-git/`: VCS build variant.
- Package directories typically include a `PKGBUILD`; build outputs (e.g.,
`*.pkg.tar.zst`) are local artifacts, not inputs.

## Build, Test, and Development Commands

Run these from the package directory you are working on (e.g., `godot-double-gh/`):

- `makepkg -si`: build and install the package(s) locally.
- `makepkg -C`: clean the build directory before a fresh build.
- `makepkg -o`: download sources without building.
- `updpkgsums`: refresh `b2sums` after updating `pkgver` or `source`.
- `makepkg --printsrcinfo > .SRCINFO`: regenerate metadata if publishing to AUR.

## Coding Style & Naming Conventions

- `PKGBUILD` uses Bash; keep indentation to two spaces and align arrays with one
    entry per line.
- Follow Arch packaging conventions: global vars in lowercase (`pkgver`,
    `pkgrel`), functions named `prepare()`, `build()`, and `package_<pkgname>()`.
- Keep numbered build/install steps as short comments when the flow is non-obvious.

## Testing Guidelines

- No `check()` function is defined, so automated tests are not run.
- Validate by building with `makepkg -si` and launching the installed binaries
    (`godot-double`, `godot-double-mono`) to confirm startup.
- For Mono packaging, confirm glue/assemblies are generated (see `build()` in `PKGBUILD`).

## Commit & Pull Request Guidelines

- This checkout has no `.git` history; no established commit message convention
    is visible.
- If contributing in a git context, use concise, imperative subjects and include
    the package name, e.g., `godot-double: bump to 4.5.1`.
- PRs should state the affected package variant(s), include updated checksums,
    and note local build verification.
