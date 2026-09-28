#
# This file defines overlays/custom modifications to upstream packages
#
{ self, inputs, ... }:
let
  electronArgs = [
    "--ozone-platform-hint=auto"
    "--enable-wayland-ime"
    "--wayland-text-input-version=3"
  ];
in
{
  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications =
    final: prev:
    {
      vscode = prev.vscode.override {
        commandLineArgs = electronArgs;
      };
      obsidian = prev.obsidian.override {
        commandLineArgs = electronArgs;
      };
      qq = prev.qq.override {
        commandLineArgs = electronArgs;
      };
      code-cursor = prev.code-cursor.override {
        commandLineArgs = (builtins.concatStringsSep " " electronArgs);
      };
    }
    //
      prev.lib.optionalAttrs (prev.stdenv.hostPlatform.isDarwin && prev.stdenv.hostPlatform.isAarch64)
        {
          # FIXIT
      kitty = prev.kitty.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./kitty-darwin-no-branch-protection.patch ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.llvmPackages.lld ];
        env = (old.env or { }) // {
          NIX_CFLAGS_LINK = "-fuse-ld=lld";
        };
        # Fix macOS notifications (kitten notify / notify_on_cmd_finish).
        # The real GUI process is Contents/MacOS/.kitty-wrapped (exec'd by the
        # makeBinaryWrapper shim), and autoSignDarwinBinariesHook ad-hoc signs it
        # with identifier ".kitty-wrapped". usernotificationsd then rejects it
        # because the signing identifier != bundle id "net.kovidgoyal.kitty"
        # (UNErrorDomain error 1). Re-sign it with the bundle id *after* the
        # auto-sign hook (which also lives in postFixupHooks, registered earlier).
        # Must be done at build time: the copied app in ~/Applications execs the
        # store copy of .kitty-wrapped, so re-signing the copy has no effect.
        postInstall = (old.postInstall or "") + ''
          _kittyResignWithBundleId() {
            local f="$out/Applications/kitty.app/Contents/MacOS/.kitty-wrapped"
            local tmp
            tmp=$(mktemp -d)
            # sign a fresh copy: the binary was already executed during the build
            cp "$f" "$tmp/"
            ${prev.darwin.sigtool}/bin/codesign -f -s - -i net.kovidgoyal.kitty "$tmp/.kitty-wrapped"
            mv "$tmp/.kitty-wrapped" "$f"
            rmdir "$tmp"
          }
          postFixupHooks+=(_kittyResignWithBundleId)
        '';
      });
      starship = prev.starship.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.llvmPackages.lld ];
        env = (old.env or { }) // {
          NIX_CFLAGS_LINK = (old.env.NIX_CFLAGS_LINK or "") + " -fuse-ld=lld";
        };
      });
        };
  # FIXME jetbrains-mono: Failure on dependency with python313Packages.picosvg
  workaround = (
    final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          picosvg = python-prev.picosvg.overridePythonAttrs (oldAttrs: {
            doCheck = false;
          });
        })
      ];
    }
  );
  add-my-pkgs = final: prev: {
    pkgs-stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
      overlays = [
        (final: prev: {
          qq = prev.qq.override {
            commandLineArgs = electronArgs;
          };
        })
      ];
    };
    pkgs-stable-with-openssl_1_1_w = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowBroken = true;
        permittedInsecurePackages = [
          "openssl-1.1.1w"
        ];
      };
    };
    my-pkgs = self.packages."${final.stdenv.hostPlatform.system}" // {
      dingtalk = final.pkgs-stable-with-openssl_1_1_w.callPackage ../packages/dingtalk { };
      lazydc = inputs.lazydc.packages.${final.stdenv.hostPlatform.system}.default;
    };
  };
  dnsctl = inputs.dnsctl-nix.overlays.default;
}
