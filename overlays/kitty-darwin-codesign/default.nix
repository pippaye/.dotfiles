# Re-sign kitty.app on darwin with a stable self-signed certificate so that
# macOS permissions (notifications, Full Disk Access, Accessibility, ...)
# survive kitty updates/rebuilds.
# Full write-up / troubleshooting: docs/kitty-darwin-codesign.md
#
# Why:
# - nixpkgs' kitty.app is ad-hoc signed per-binary with identifiers like
#   `kitty` / `.kitty-wrapped` and no bundle seal. usernotificationsd rejects
#   such clients because the signing identifier != CFBundleIdentifier.
# - ad-hoc signatures have no certificate, so TCC/usernoted can only pin the
#   cdhash, which changes on every rebuild => every update = new app = re-prompt.
#   Signing with a fixed certificate makes the designated requirement
#   `identifier "<bundleId>" and certificate root = H"<cert hash>"`, which stays
#   the same across builds, so grants persist.
#
# How (cache-friendly): upstream `kitty` is NOT rebuilt, it still comes from
# cache.nixos.org. This is a small wrapper derivation that copies kitty.app,
# regenerates the launcher and signs the copy; it takes a few seconds.
# - `Contents/MacOS/kitty` is a makeCWrapper that hard-codes the upstream
#   store path of `.kitty-wrapped`. If left as is, the process that talks to
#   usernotificationsd would be the *unsigned upstream* binary. So it is
#   regenerated to exec the copy inside $out (same PATH suffix as upstream).
#   It is the only file in the bundle that references upstream $out; every
#   other link inside the bundle is relative.
# - Other outputs (terminfo, shell_integration, kitten) are reused from
#   upstream as-is; they contain no signed code that matters here.
#
# Bundle identifier: usernoted remembers identifiers it has already asked
# about; if the prompt is dismissed / times out, that identifier is dead
# (no prompt, no entry in System Settings). `net.kovidgoyal.kitty` and
# `net.kovidgoyal.kitty.nix` are dead on this machine. Do NOT change
# `bundleId` casually: it is part of the designated requirement, changing it
# drops every granted permission.
#
# Key material (see `just kitty-darwin-codesign-init`):
# - certFile: public cert, committed next to this file, part of the drv hash.
# - keyFile:  private key, NOT in the nix store. Read at build time by the
#   nixbld users, so it must be `root:nixbld 0640` and `sandbox = false`.
#
# Use `final` for everything except `kitty` itself. On darwin the stdenv
# re-overrides some packages (e.g. `ncurses`) *after* user overlays, so
# `prev.ncurses` is a different, uncached derivation than the `ncurses`
# upstream kitty was built against (`final.ncurses`). Using `prev.*` here
# made every deploy rebuild ncurses from source.
{
  final,
  prev,
  certFile ? ./cert.pem,
  keyFile ? "/var/lib/kitty-darwin-codesign/key.pem",
}:
let
  inherit (final) lib;
  kitty = prev.kitty;
  bundleId = "net.kovidgoyal.kitty.nixpkgs";
  # Same runtime PATH suffix upstream bakes into its launcher (upstream uses
  # callPackage, i.e. `final`). Verified against the upstream launcher at
  # build time below.
  runtimePath = lib.makeBinPath [
    final.imagemagick
    final.ncurses.dev
    final.shader-slang
  ];
in
if !final.stdenv.hostPlatform.isDarwin then
  kitty
else if !builtins.pathExists certFile then
  throw "kitty-darwin-codesign: ${toString certFile} missing, run `just kitty-darwin-codesign-init` first"
else
  final.runCommand "${kitty.name}-codesigned"
    {
      nativeBuildInputs = [
        final.makeBinaryWrapper
        final.rcodesign
      ];
      # Nothing to fetch from a substituter; building is just cp + sign.
      preferLocalBuild = true;
      allowSubstitutes = false;
      # Changing the cert must produce a new store path.
      inherit certFile;
      passthru = kitty.passthru // {
        unsigned = kitty;
        inherit (kitty) terminfo shell_integration kitten;
      };
      meta = kitty.meta // {
        platforms = lib.platforms.darwin;
      };
    }
    ''
      # stdenv already runs with `set -e`; `set -u` would break makeBinaryWrapper's hook.
      key=${lib.escapeShellArg keyFile}
      if [ ! -r "$key" ]; then
        echo "error: cannot read kitty-darwin-codesign key $key (as $(id -un))." >&2
        echo "       run \`just kitty-darwin-codesign-init\` (needs sudo), and make sure nix sandbox is off." >&2
        exit 1
      fi

      src=${kitty}
      app="$out/Applications/kitty.app"

      mkdir -p "$out/Applications"
      # -R keeps the relative symlinks inside the bundle intact.
      cp -R "$src/Applications/kitty.app" "$app"
      chmod -R u+w "$out"

      # Our PATH suffix must be exactly what upstream baked in; otherwise we'd
      # silently pull in (and possibly build) different runtime deps.
      if ! grep -aqF "'$src/bin:${runtimePath}'" "$src/Applications/kitty.app/Contents/MacOS/kitty"; then
        echo "error: runtime PATH differs from upstream kitty launcher:" >&2
        echo "  ours:     $src/bin:${runtimePath}" >&2
        echo "  upstream: $(strings "$src/Applications/kitty.app/Contents/MacOS/kitty" | grep -m1 "^$src/bin:")" >&2
        exit 1
      fi

      # Launcher: must exec the .kitty-wrapped inside *this* bundle.
      rm "$app/Contents/MacOS/kitty"
      makeBinaryWrapper "$app/Contents/MacOS/.kitty-wrapped" "$app/Contents/MacOS/kitty" \
        --suffix PATH : "$out/bin:${runtimePath}"
      if grep -aqF "$src" "$app/Contents/MacOS/kitty"; then
        echo "error: launcher still references upstream $src" >&2; exit 1
      fi

      /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${bundleId}" "$app/Contents/Info.plist"

      # `kitty` is the bundle main executable (signed with the bundle id by
      # rcodesign automatically); `.kitty-wrapped` is the process that talks
      # to usernotificationsd, so it must carry the bundle identifier too.
      rcodesign sign \
        --pem-file "$key" --pem-file "$certFile" \
        --binary-identifier "Contents/MacOS/.kitty-wrapped:${bundleId}" \
        --binary-identifier "Contents/MacOS/kitten:net.kovidgoyal.kitten" \
        "$app" > /dev/null

      /usr/bin/codesign --verify --deep --strict "$app"
      /usr/bin/codesign -d -r- "$app" 2>&1 | grep -q 'identifier "${bundleId}" and certificate root' \
        || { echo "error: unexpected designated requirement" >&2; /usr/bin/codesign -d -r- "$app" >&2; exit 1; }
      id=$(/usr/bin/codesign -dv "$app/Contents/MacOS/.kitty-wrapped" 2>&1 | sed -n 's/^Identifier=//p')
      [ "$id" = "${bundleId}" ] || { echo "error: .kitty-wrapped identifier is '$id'" >&2; exit 1; }

      # Everything outside the bundle: same layout as upstream, pointing at our app.
      mkdir -p "$out/bin"
      ln -s ../Applications/kitty.app/Contents/MacOS/kitty "$out/bin/kitty"
      ln -s ../Applications/kitty.app/Contents/MacOS/kitten "$out/bin/kitten"
      ln -s "$src/share" "$out/share"
      # propagated-user-env-packages pulls in the terminfo output.
      cp -R "$src/nix-support" "$out/nix-support"
      chmod -R u+w "$out/nix-support"
    ''
