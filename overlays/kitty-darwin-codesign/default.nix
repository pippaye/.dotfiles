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
{
  prev,
  certFile ? ./cert.pem,
  keyFile ? "/var/lib/kitty-darwin-codesign/key.pem",
}:
let
  bundleId = "net.kovidgoyal.kitty.nixpkgs";
in
if !prev.stdenv.hostPlatform.isDarwin then
  prev.kitty
else if !builtins.pathExists certFile then
  throw "kitty-darwin-codesign: ${toString certFile} missing, run `just kitty-darwin-codesign-init` first"
else
  prev.kitty.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.buildPackages.rcodesign ];
    # Appended in preFixup so it runs *after* autoSignDarwinBinariesHook
    # (which registers itself in postFixupHooks when its setup hook is sourced).
    preFixup = (old.preFixup or "") + ''
      signKittyBundle() {
        local app="$out/Applications/kitty.app"
        local key=${prev.lib.escapeShellArg keyFile}
        if [ ! -r "$key" ]; then
          echo "error: cannot read kitty-darwin-codesign key $key (as $(id -un))." >&2
          echo "       run \`just kitty-darwin-codesign-init\` (needs sudo), and make sure nix sandbox is off." >&2
          return 1
        fi
        echo "signing $app as ${bundleId} with ${certFile}"
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${bundleId}" "$app/Contents/Info.plist"
        # `kitty` (bundle main executable) is a makeCWrapper that execs the
        # store path of `.kitty-wrapped`; the latter is the process that talks
        # to usernotificationsd, so it must carry the bundle identifier too.
        rcodesign sign \
          --pem-file "$key" --pem-file ${certFile} \
          --binary-identifier "Contents/MacOS/.kitty-wrapped:${bundleId}" \
          --binary-identifier "Contents/MacOS/kitten:net.kovidgoyal.kitten" \
          "$app" > /dev/null
        /usr/bin/codesign --verify --deep --strict "$app"
        /usr/bin/codesign -d -r- "$app" 2>&1 | grep -q 'identifier "${bundleId}" and certificate root' \
          || { echo "error: unexpected designated requirement" >&2; /usr/bin/codesign -d -r- "$app" >&2; return 1; }
        local id
        id=$(/usr/bin/codesign -dv "$app/Contents/MacOS/.kitty-wrapped" 2>&1 | sed -n 's/^Identifier=//p')
        [ "$id" = "${bundleId}" ] || { echo "error: .kitty-wrapped identifier is '$id'" >&2; return 1; }
      }
      postFixupHooks+=(signKittyBundle)
    '';
  })
