# Default configuration for the automation scripts.
# Override locally in config.local.sh.

GH_REPO="Norpyx-Godot/godot-double"
RELEASE_PREFIX="v"
AUR_REMOTE="origin"
MAKEPKG_ARGS="-sf --noconfirm"

AUR_KEYWORDS=(
  godot
  godot-engine
  game-engine
  game-development
  gamedev
  editor
  2d
  3d
  double-precision
  floating-point
  large-worlds
  simulation
  physics
  mono
  dotnet
  csharp
)

AUR_BIN_KEYWORDS=(
  "${AUR_KEYWORDS[@]}"
  binary
  prebuilt
)
