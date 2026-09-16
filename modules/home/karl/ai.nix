{ inputs, ... }:

{
  flake.homeModules.karl-ai =
    { config, pkgs, ... }:
    let
      codex = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      openai-oauth = pkgs.callPackage ../../../packages/openai-oauth {
        openaiOAuthSrc = inputs.openai-oauth;
      };
      oauthHost = "127.0.0.1";
      oauthPort = 10531;
      oauthFile = "${config.home.homeDirectory}/.codex/auth.json";
      start-openai-oauth = pkgs.writeShellScript "start-openai-oauth" ''
        # Codex and openai-oauth intentionally share this credential file.
        while [[ ! -s ${oauthFile} ]]; do
          ${pkgs.coreutils}/bin/sleep 5
        done

        exec ${openai-oauth}/bin/openai-oauth serve \
          --host ${oauthHost} \
          --port ${toString oauthPort} \
          --oauth-file ${oauthFile} \
          --codex-version ${codex.version}
      '';
    in
    {
      home.packages = [
        codex
        openai-oauth
      ];

      programs.aichat = {
        enable = true;
        settings = {
          model = "openai-oauth:gpt-5.6-sol";
          clients = [
            {
              type = "openai-compatible";
              name = "openai-oauth";
              api_base = "http://${oauthHost}:${toString oauthPort}/v1";
              models = [
                {
                  name = "gpt-5.6-sol";
                  supports_function_calling = true;
                }
                {
                  name = "gpt-5.6-terra";
                  supports_function_calling = true;
                }
              ];
            }
          ];
        };
      };

      systemd.user.services.openai-oauth = {
        Unit = {
          Description = "OpenAI OAuth compatibility proxy for aichat";
          Documentation = "https://github.com/EvanZhouDev/openai-oauth";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = start-openai-oauth;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
