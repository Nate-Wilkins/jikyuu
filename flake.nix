{
  description                                                            = "Jikyuu";

  inputs                                                                 = {
    systems.url                                                          = "path:./flake.systems.nix";
    systems.flake                                                        = false;

    nixpkgs.url                                                          = "github:Nate-Wilkins/nixpkgs/nixos-unstable";

    flake-utils.url                                                      = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows                                   = "systems";

    task-documentation.url                                               = "gitlab:ox_os/task-documentation/5.0.2";
    task-documentation.inputs.systems.follows                            = "systems";
    task-documentation.inputs.nixpkgs.follows                            = "nixpkgs";
    task-documentation.inputs.flake-utils.follows                        = "flake-utils";
    task-documentation.inputs.fenix.follows                              = "fenix";
    task-documentation.inputs.asciinema-automation.follows               = "asciinema-automation";
    task-documentation.inputs.jikyuu.follows                             = "";
    task-documentation.inputs.rust-analyzer-src.follows                  = "rust-analyzer-src";
    task-documentation.inputs.task-runner.follows                        = "task-runner";

    task-runner.url                                                      = "gitlab:ox_os/task-runner/4.0.1";
    task-runner.inputs.systems.follows                                   = "systems";
    task-runner.inputs.nixpkgs.follows                                   = "nixpkgs";
    task-runner.inputs.flake-utils.follows                               = "flake-utils";
    task-runner.inputs.fenix.follows                                     = "fenix";
    task-runner.inputs.asciinema-automation.follows                      = "asciinema-automation";
    task-runner.inputs.jikyuu.follows                                    = "";
    task-runner.inputs.rust-analyzer-src.follows                         = "rust-analyzer-src";
    task-runner.inputs.task-documentation.follows                        = "task-documentation";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Transatives
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    asciinema-automation.url                                             = "github:Nate-Wilkins/asciinema-automation/2.0.7";
    asciinema-automation.inputs.systems.follows                          = "systems";
    asciinema-automation.inputs.nixpkgs.follows                          = "nixpkgs";
    asciinema-automation.inputs.flake-utils.follows                      = "flake-utils";
    asciinema-automation.inputs.fenix.follows                            = "fenix";
    asciinema-automation.inputs.jikyuu.follows                           = "";
    asciinema-automation.inputs.rust-analyzer-src.follows                = "rust-analyzer-src";

    rust-analyzer-src.url                                                = "github:rust-lang/rust-analyzer/nightly";
    rust-analyzer-src.flake                                              = false;

    fenix.url                                                            = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows                                         = "nixpkgs";
    fenix.inputs.rust-analyzer-src.follows                               = "rust-analyzer-src";
  };

  outputs                                                                = {
    nixpkgs,
    flake-utils,
    fenix,
    task-runner,
    task-documentation,
    ...
  }:
    let
      mkPkgs                                                             =
        system:
          pkgs: (
            # NixPkgs
            import pkgs { inherit system; }
            //
            # Custom Packages.
            {
              task-documentation                                         = task-documentation.defaultPackage."${system}";
            }
          );

    in (
      flake-utils.lib.eachDefaultSystem (system: (
        let
          pkgs                                                           = mkPkgs system nixpkgs;
          manifest                                                       = (pkgs.lib.importTOML ./Cargo.toml).package;
          environment                                                    = {
            inherit pkgs;
            inherit manifest;
            toolchain                                                    = fenix.packages.${system}.minimal.toolchain;
          };
          name                                                           = manifest.name;
        in rec {
          packages.${name}                                               = pkgs.callPackage ./default.nix environment;
          legacyPackages                                                 = packages;

          # `nix build`
          defaultPackage                                                 = packages.${name};

          # `nix run`
          apps.${name}                                                   = flake-utils.lib.mkApp {
            inherit name;
            drv                                                          = packages.${name};
          };
          defaultApp                                                     = apps.${name};

          # `nix develop`
          devShells.default                                              = import ./shell/default.nix (
            environment
          // {
            taskRunner                                                   = task-runner.taskRunner.${system};
          });
        }
      )
    )
  );
}
