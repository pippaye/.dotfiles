{ pkgs, ... }:
with pkgs;
[
  strace
  # ltrace
  perf
  sysstat
]
