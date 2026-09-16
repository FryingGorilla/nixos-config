{
  lib,
  buildNpmPackage,
  makeWrapper,
  nodejs,
  openaiOAuthSrc,
}:

let
  upstreamPackage = builtins.fromJSON (
    builtins.readFile "${openaiOAuthSrc}/packages/openai-oauth/package.json"
  );
  package = builtins.fromJSON (builtins.readFile ./package.json);
  version = package.dependencies.openai-oauth;
in
assert upstreamPackage.version == version;
buildNpmPackage {
  pname = "openai-oauth";
  inherit version;

  src = ./.;
  npmDepsHash = "sha256-Zja0oMGlC6bhaGyHB879CZ8WBv1jEQWW+0twCxz+3os=";
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/openai-oauth $out/bin
    cp -r node_modules $out/lib/openai-oauth/
    makeWrapper ${nodejs}/bin/node $out/bin/openai-oauth \
      --add-flags "$out/lib/openai-oauth/node_modules/openai-oauth/dist/cli.js"

    runHook postInstall
  '';

  meta = {
    description = upstreamPackage.description;
    homepage = upstreamPackage.homepage;
    license = lib.licenses.asl20;
    mainProgram = "openai-oauth";
    platforms = nodejs.meta.platforms;
  };
}
