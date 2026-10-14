{
  outputs,
  inputs,
  ...
}:
let
  inherit (inputs) deploy-rs;
in
{
  nodes = {
    # desk00-u265kf-lan = {
    #   hostname = "lan.void";
    #   profiles = {
    #     system = {
    #       sshUser = "deployee";
    #       user = "root";
    #       path = deploy-rs.lib.x86_64-linux.activate.nixos outputs.nixosConfigurations.desk00-u265kf-lan;
    #     };
    #     ashenye = {
    #       sshUser = "ashenye";
    #       user = "ashenye";
    #       path =
    #         deploy-rs.lib.x86_64-linux.activate.home-manager
    #           outputs.homeConfigurations."ashenye@desk00-u265kf-lan";
    #     };
    #   };
    # };
    # lap00-xiaoxin-mei = {
    #   hostname = "mei.void";
    #   profiles = {
    #     system = {
    #       user = "root";
    #       sshUser = "deployee";
    #       path = deploy-rs.lib.x86_64-linux.activate.nixos outputs.nixosConfigurations.lap00-xiaoxin-mei;
    #     };
    #     ashenye = {
    #       user = "ashenye";
    #       sshUser = "ashenye";
    #       path =
    #         deploy-rs.lib.x86_64-linux.activate.home-manager
    #           outputs.homeConfigurations."ashenye@lap00-xiaoxin-mei";
    #     };
    #   };
    # };
    rutr01-j4105-qingloong = {
      hostname = "qingloong.void";
      profiles = {
        system = {
          user = "root";
          sshUser = "deployee";
          path = deploy-rs.lib.x86_64-linux.activate.nixos outputs.nixosConfigurations.rutr01-j4105-qingloong;
        };
        ashenye = {
          user = "ashenye";
          sshUser = "ashenye";
          path =
            deploy-rs.lib.x86_64-linux.activate.home-manager
              outputs.homeConfigurations."ashenye@rutr01-j4105-qingloong";
        };
      };
    };
    # lap01-macm4-mume = {
    #   hostname = "mume.void";
    #   remoteBuild = true;
    #   profiles = {
    #     system = {
    #       sshUser = "deployee";
    #       user = "root";
    #       path = deploy-rs.lib.aarch64-darwin.activate.darwin outputs.darwinConfigurations.lap01-macm4-mume;
    #     };
    #   };
    # };
  };
  sshOpts = [
    "-p"
    "2222"
    "-i"
    "~/.config/sops-nix/secrets/REMOTE_DEPLOY_PRIVKEY"
  ];
}
