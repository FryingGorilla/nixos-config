{ lib, ... }:

{
  options.flake = {
    homeConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = "Home Manager configurations exported by the flake";
    };

    homeModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
      description = "Home Manager modules exported by the flake";
    };

  };

  config.systems = [ "x86_64-linux" ];
}
