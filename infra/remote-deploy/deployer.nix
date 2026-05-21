hosts: # lists of { hostname, domain, port }
{
  paths,
  lib,
  config,
  ...
}:
{
  sops.secrets = {
    REMOTE_DEPLOY_PRIVKEY = {
      mode = "0400";
      sopsFile = "${paths.secrets}/infra.yaml";
    };
  };
  programs.ssh.settings =
    hosts
    |> lib.map (
      {
        hostname,
        domain,
        port,
      }:
      {
        name = "${hostname}-deploy";
        value = {
          hostname = domain;
          user = "deployee";
          inherit port;
          identityFile = config.sops.secrets.REMOTE_DEPLOY_PRIVKEY.path;
        };
      }
    )
    |> lib.listToAttrs;
}
