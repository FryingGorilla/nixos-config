{ ... }:

{
  flake.homeModules.karl = { ... }: {
    home = {
      username = "karl";
      homeDirectory = "/home/karl";
      stateVersion = "26.05";
    };

    xdg.enable = true;
  };
}
