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
        openssl
        toolchain
      ];
      CARGO                                       = "${toolchain}/bin/cargo";
      PKG_CONFIG_PATH                             = "${pkgs.openssl.dev}/lib/pkgconfig";

      cargoSha256                                 = "sha256-0hfmV4mbr3l86m0X7EMYTOu/b+BjueVEbbyQz0KgOFY=";
      cargoLock.lockFile                          = ./Cargo.lock;
      meta                                        = { };

      doCheck                                     = false; # Enabling is Impure since postFixup isn't accounted for.
      postFixup                                   = ''
        wrapProgram "$out/bin/${name}" \
          --set PATH ${lib.makeBinPath [ toolchain ]} \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.openssl ]}
      '';
    })
  )

