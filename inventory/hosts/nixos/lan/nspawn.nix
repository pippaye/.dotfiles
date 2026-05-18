{ config, lib, ... }:
let
  ctr0 = "red";
  ctr1 = "azure";
in
{
  systemd.nspawn."${ctr0}" = {
    networkConfig = {
      MACVLAN = "lan0:eth0";
    };
    execConfig = {
      Boot = true;
      PrivateUsers = false;
      Capability = "all";
      Environment = [
        "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
        "PATH=/run/current-system/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      ];
      Hostname = "${ctr0}";
      ResolvConf = "bind-host";
    };
    filesConfig = {
      Bind = [
        "/dev/nvidia0"
        "/dev/nvidiactl"
        "/dev/nvidia-modeset"
        "/dev/nvidia-uvm"
        "/dev/nvidia-uvm-tools"
        # "/dev/nvidia-caps"
        "/dev/dri"
      ];
      BindReadOnly = [
        "/run/current-system/sw"
        "/run/opengl-driver"
        "/run/opengl-driver-32"
        "/nix"
      ];
    };
  };

  systemd.services."systemd-nspawn@${ctr0}" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      # Drop the template's -U (user namespace). It breaks writes to /etc/shadow
      # unless the rootfs is idmapped.
      # ExecStart = lib.mkForce [
      #   ""
      #   "systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth --settings=override --machine=%i"
      # ];
      # # Avoid pam_limits trying to raise RLIMIT_NOFILE without CAP_SYS_RESOURCE.
      # LimitNOFILE = "infinity";
      # # Drop systemd's default syscall filter for this unit; it blocks prlimit64
      # # in this container and causes passwd to fail with EPERM.
      # # Use an explicit empty assignment so systemd actually resets the filter.
      # SystemCallFilter = lib.mkForce [ "" ];
      DevicePolicy = "closed";
      DeviceAllow = [
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-modeset rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
        "/dev/dri/card1 rw"
        "/dev/dri/renderD128 rw"
      ];
    };
    # wantedBy = [ "multi-user.target" ];
  };

  systemd.nspawn."${ctr1}" = {
    networkConfig = {
      MACVLAN = "lan0:eth0";
    };
    execConfig = {
      Boot = true;
      PrivateUsers = false;
      Capability = "all";
      Environment = [
        "PATH=/run/current-system/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      ];
      Hostname = "${ctr1}";
      ResolvConf = "bind-host";
    };
    filesConfig = {
      BindReadOnly = [
        "/nix"
        "/run/current-system/sw"
      ];
    };
  };

}
