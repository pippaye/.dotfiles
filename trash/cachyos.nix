{
  inputs,
  pkgs,
  lib,
  paths,
  ...
}:
let
  # kernel_6_18_3 = pkgs.linux_6_18.override {
  #   ignoreConfigErrors = true;
  #   argsOverride = rec {
  #     version = "6.18.3";
  #     modDirVersion = version;
  #     src = pkgs.fetchurl {
  #       url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
  #       hash = "sha256-eoh5FnuJxLrgd9bznE8hMHafBdva0qrZFK2rmvt9f5o=";
  #     };
  #   };
  # };
  linuxPackages_6_18_3 = pkgs.linuxPackagesFor kernel_6_18_3;
  # cachyosKernel = pkgs.cachyosKernels.linux-cachyos-bore-lto.override {
  #   pname = "my-cachyos";
  #   processorOpt = "x86_64-v3";
  #   lto = "thin";
  # };
in
{
  virtualisation.docker.enable = true;
  users.users.ashenye.extraGroups = [ "docker" ];
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  #boot.kernelPackages = lib.mkDefault (pkgs.linuxKernel.packagesFor cachyosKernel);
  specialisation =
    let
      boot = {
        kernelParams = [
          "quiet"
          "loglevel=3"

          # 降噪
          "nowatchdog"
          "intel_idle.max_cstate=1"
          "processor.max_cstate=1"
          "cpufreq.default_governor=performance"
          "noautogroup"

          # 做 isolated-core latency 实验时再开
          # "nohz_full=2-15"
          # "rcu_nocbs=2-15"
          # "irqaffinity=0-1"

          # 只在需要稳定地址做符号化时再开
          # "nokaslr"

          # 这两个要么固定为开，要么固定为关，并在论文里披露
          # "nosmt"
          # "mitigations=off"
        ];

        kernel.sysctl = {
          # 观测权限
          "kernel.perf_event_paranoid" = -1;
          # "kernel.kptr_restrict" = 0;
          # "kernel.unprivileged_bpf_disabled" = 0;

          # 内存噪声控制
          "vm.swappiness" = 0;
          # "kernel.numa_balancing" = 0;

          # 只在 RT/DL 论文里再考虑
          # "kernel.sched_rt_runtime_us" = -1;

          # 只在 tracing runs 打开
          # "kernel.sched_schedstats" = 1;
          # "kernel.task_delayacct" = 1;
        };
      };
    in
    {

      # "nsdi-eevdf-6.18.3".configuration = {
      #   boot = boot // {
      #     kernelPackages = linuxPackages_6_18_3;
      #   };
      # };
      # "nsdi-bore-6.18.3".configuration = {
      #   boot = boot // {
      #     kernelPackages = linuxPackages_6_18_3;
      #     kernelPatches = [
      #       {
      #         name = "bore";
      #         patch = pkgs.fetchpatch {
      #           url = "https://raw.githubusercontent.com/firelzrd/bore-scheduler/178fd0a4bec8ad7b66facdee879602eb157c17a1/patches/stable/linux-6.18-bore/0001-linux6.18.3-bore-6.6.1.patch";
      #           hash = "sha256-P4FeNqAPCzRqgTYvfhCovV93pFmx2hNtwUhl3cn12qM=";
      #         };
      #         structuredExtraConfig = {
      #           SCHED_BORE = lib.kernel.yes;
      #         };
      #       }
      #     ];
      #   };
      # };
      # "nixos-lts".configuration = {
      #   boot.kernelPackages = pkgs.linuxPackages;
      # };
    };
}
