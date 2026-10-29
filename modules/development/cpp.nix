{ ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.cpp = pkgs.mkShell {
      buildInputs = [ pkgs.boost ];
    };
  };
}
