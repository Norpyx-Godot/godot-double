# godot-double-gh

This directory is the release hub for the Godot double-precision AUR packages.
The `godot-double` package is built from its own `PKGBUILD`, then its artifact
is copied here to create a GitHub release. The `godot-double-bin` package is
generated from that release asset, so both AUR variants flow through this
directory.

## Repository Layout

This directory expects to live alongside the other package roots:

- `../godot-double/`: source build; produces the `.pkg.tar.zst` artifact.
- `../godot-double-bin/`: binary package generated from the GitHub release asset.
- `../godot-double-gh/`: this directory; hosts release artifacts and scripts.

## Scripts

### `hydrate-bin.sh`

Generates the `godot-double-bin` PKGBUILD using a built package from
`../godot-double/`.

- Reads `pkgver`/`pkgrel` from `../godot-double/PKGBUILD`.
- Copies the latest non-Mono `.pkg.tar.zst` into this directory.
- Computes SHA256 and derives the GitHub release URL from this repo's `origin`.
- Writes `../godot-double-bin/PKGBUILD` and regenerates `.SRCINFO`.
- Does not run `makepkg`; the build step in the script is commented out.

Example (after building `godot-double`):

```bash
./hydrate-bin.sh
```

### `publish.sh`

Publishes the release and commits the binary package metadata.

- Runs `git clean -dxf` in `godot-double`, `godot-double-bin`, and here.
- Copies the latest built package into this directory.
- Creates a GitHub release tag `v${pkgver}-${pkgrel}` with the artifact.
- Commits `../godot-double-bin/PKGBUILD` and `.SRCINFO`.
- Does not push; `git push` is commented out in the script.

Example (requires `gh` CLI):

```bash
./publish.sh
```

## Typical Workflow (Release Order)

1. Check the latest Godot release on GitHub and update `../godot-double/PKGBUILD`
   (`pkgver`, `pkgrel`, `source`, and any patches).
2. Refresh checksums and metadata in `../godot-double/`:
   - `updpkgsums`
   - `makepkg --printsrcinfo > .SRCINFO`
3. Build the source package to produce the `.pkg.tar.zst` artifact:
   - `makepkg -si`
4. Run `./hydrate-bin.sh` to generate `../godot-double-bin/PKGBUILD` and
   `../godot-double-bin/.SRCINFO` from the release asset URL.
5. Run `./publish.sh` to create the GitHub release and commit the binary
   package metadata. Ensure this repo's `origin` points to the release host.
6. Push AUR updates manually:
   - `git add PKGBUILD .SRCINFO && git commit -m "v${pkgver}-${pkgrel}" && git push`
     in `../godot-double/`
   - `git push` in `../godot-double-bin/` (the commit is created by `publish.sh`)
