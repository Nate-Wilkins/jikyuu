{
  description                                                 = "Jikyuu";

  inputs                                                      = {
    nixpkgs.url                                               = "github:NixOS/nixpkgs/23.11";

    flake-utils.url                                           = "github:numtide/flake-utils";

    gitignore.url                                             = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows                          = "nixpkgs";

    fenix.url                                                 = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows                              = "nixpkgs";

    asciinema-automation.url                                  = "github:Nate-Wilkins/asciinema-automation/1.0.1";
    asciinema-automation.inputs.nixpkgs.follows               = "nixpkgs";
    asciinema-automation.inputs.flake-utils.follows           = "flake-utils";

    jikyuu.url                                                = "github:Nate-Wilkins/jikyuu/1.0.1";
    jikyuu.inputs.nixpkgs.follows                             = "nixpkgs";
    jikyuu.inputs.flake-utils.follows                         = "flake-utils";
    jikyuu.inputs.fenix.follows                               = "fenix";

    task-documentation.url                                    = "gitlab:ox_os/task-documentation/3.0.1";
    task-documentation.inputs.nixpkgs.follows                 = "nixpkgs";
    task-documentation.inputs.flake-utils.follows             = "flake-utils";
    task-documentation.inputs.gitignore.follows               = "gitignore";
    task-documentation.inputs.fenix.follows                   = "fenix";
    task-documentation.inputs.asciinema-automation.follows    = "asciinema-automation";
    task-documentation.inputs.jikyuu.follows                  = "jikyuu";

    task-runner.url                                           = "gitlab:ox_os/task-runner/1.0.0";
    task-runner.inputs.nixpkgs.follows                        = "nixpkgs";
    task-runner.inputs.flake-utils.follows                    = "flake-utils";
    task-runner.inputs.gitignore.follows                      = "gitignore";
    task-runner.inputs.fenix.follows                          = "fenix";
    task-runner.inputs.asciinema-automation.follows           = "asciinema-automation";
    task-runner.inputs.jikyuu.follows                         = "jikyuu";
    task-runner.inputs.task-documentation.follows             = "task-documentation";
  };

  outputs                                           = {
    nixpkgs,
    flake-utils,
    fenix,
    task-runner,
    task-documentation,
    ...
  }:
    let
      mkPkgs                                        =
        system:
          pkgs: (
            # NixPkgs
            import pkgs { inherit system; }
            //
            # Custom Packages.
            {
              task-documentation                    = task-documentation.defaultPackage."${system}";
            }
          );

    in (
      flake-utils.lib.eachDefaultSystem (system: (
        let
          pkgs                                      = mkPkgs system nixpkgs;
          manifest                                  = (pkgs.lib.importTOML ./Cargo.toml).package;
          environment                               = {
            inherit pkgs;
            inherit manifest;
            toolchain                               = fenix.packages.${system}.minimal.toolchain;
          };
          name                                      = manifest.name;
        in rec {
          packages.${name}                          = pkgs.callPackage ./default.nix environment;
          legacyPackages                            = packages;

          # `nix build`
          defaultPackage                            = packages.${name};

          # `nix run`
          apps.${name}                              = flake-utils.lib.mkApp {
            inherit name;
            drv                                     = packages.${name};
          };
          defaultApp                                = apps.${name};

          # `nix develop`
          devShells.default                         = import ./shell/default.nix (
            environment
          // {
            taskRunner                              = task-runner.taskRunner.${system};
          });
        }
      )
    )
  );
}
