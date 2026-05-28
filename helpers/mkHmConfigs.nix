{
  inputs,
  paths,
  ...
}:
{
  users,
  hosts ? { },
  specialArgs,
  ...
}:
users
|> builtins.mapAttrs (
  fullyQualifiedUserName: userInfo:
  let
    lib = inputs.nixpkgs.lib;
    splitFullyQualifiedUsername = import ./splitFullyQualifiedUsername.nix;
    inherit (splitFullyQualifiedUsername { inherit lib fullyQualifiedUserName; }) username hostname;
    userInfoBase = {
      inherit username hostname;
      userid = fullyQualifiedUserName;
    }
    // userInfo;
    hostInfo =
      if builtins.hasAttr userInfoBase.hostname hosts then
        hosts.${userInfoBase.hostname}
      else
        { };
    system =
      userInfo.system or (
        hostInfo.system or (
          if builtins.elem "darwin" (hostInfo.tags or [ ]) then "aarch64-darwin" else "x86_64-linux"
        )
      );
    userInfo' = userInfoBase // { inherit system; };
    isLinux = lib.strings.hasInfix "linux" system;
    isDarwin = lib.strings.hasInfix "darwin" system;
  in
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    extraSpecialArgs = specialArgs // {
      userInfo = userInfo';
      inherit isDarwin isLinux;
    };
    modules = [
      {
        imports =
          let
            roleConfigs =
              if userInfo ? role then
                [
                  "${paths.hmRoles}/${userInfo.role}"
                ]
              else
                [ ];
            hmConfigs =
              if !(userInfo ? hmConfig) then
                roleConfigs
              else if builtins.isPath userInfo.hmConfig || builtins.isString userInfo.hmConfig then
                [
                  userInfo.hmConfig
                ]
                ++ roleConfigs
              else
                userInfo.hmConfig.extra
                ++ roleConfigs
                ++ [
                  userInfo.hmConfig.main
                ];
          in
          hmConfigs;
        home.username = username;
      }
    ];
  }
)
