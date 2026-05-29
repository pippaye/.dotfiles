{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];
  # use systemd-boot default
  disko.devices = {
    disk = {
      main = {
        # TODO
        device = "/dev/vda";
        imageSize = "600G";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # UEFI 分区 (ESP)
            boot = {
              name = "boot";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "512G";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/rootfs" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/";
                  };
                  # Subvolume name is the same as the mountpoint
                  "/home" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/home";
                  };
                  "/nix" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/nix";
                  };
                };
                mountpoint = "/";
              };
            };
            lvm = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "data";
              };
            };
          };
        };
      };
    };
  };
}
