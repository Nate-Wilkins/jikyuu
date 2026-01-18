{
  pkgs,
  lib,
  manifest,
  toolchain
}:
  let
    name                                          = manifest.name;
    version                                       = manifest.version;
  in (
    ((pkgs.makeRustPlatform {
      cargo                                       = toolchain;
      rustc                                       = toolchain;
    }).buildRustPackage {
      buildType                                   = "release";
      pname                                       = name;
      version                                     = version;
      src                                         = lib.cleanSource ./.;

      nativeBuildInputs                           = with pkgs; [
        makeWrapper
        pkg-config
        autoPatchelfHook
        toolchain
      ];
      buildInputs = with pkgs; [
        openssl
        stdenv.cc.cc.lib
      ];
      CARGO                                       = "${toolchain}/bin/cargo";

      cargoSha256                                 = "sha256-0hfmV4mbr3l86m0X7EMYTOu/b+BjueVEbbyQz0KgOFY=";
      cargoLock.lockFile                          = ./Cargo.lock;
      meta                                        = { };

      doCheck                                     = false; # Enabling is Impure since postFixup isn't accounted for.
      postFixup                                   = ''
        wrapProgram "$out/bin/${name}" \
          --set PATH ${lib.makeBinPath [ toolchain ]}
      '';
    })
  )

