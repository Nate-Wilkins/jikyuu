{ pkgs, toolchain, ... }: (
  let
    #
    # Run help.
    #
    task_help                                           = taskRunner.mkTask {
      name                                              = "help";
      dependencies                                      = with pkgs; [
        coreutils           # /bin/echo
      ];
      src                                               = with pkgs; ''
        ${coreutils}/bin/echo "                                                                     "
        ${coreutils}/bin/echo "Usage                                                                "
        ${coreutils}/bin/echo "   clean                  Run cleanup on temporary files.            "
        ${coreutils}/bin/echo "   docs                   Run documentation generator.               "
        ${coreutils}/bin/echo "   build                  Run build for the project.                 "
        ${coreutils}/bin/echo "   test                   Run test for the project.                  "
        ${coreutils}/bin/echo "   show                   Run show info for the flake.               "
        ${coreutils}/bin/echo "   run                    Run the project.                           "
        ${coreutils}/bin/echo "   help                   Run help.                                  "
        ${coreutils}/bin/echo "                                                                     "
      '';
    };

    #
    # Run cleanup on ignored files.
    #
    task_clean                                                = taskRunner.mkTask {
      name                                                    = "clean";
      dependencies                                            = with pkgs; [
        coreutils           # /bin/echo
        findutils           # /bin/find  /bin/xargs
        git                 # /bin/git
      ];
      isolate                                                 = false;
      src                                                     = with pkgs; ''
        # Delete all ignored files.
        ${git}/bin/git ls-files -o --ignored --exclude-standard | ${findutils}/bin/xargs rm -rf

        # Delete all empty directories.
        ${findutils}/bin/find . -type d -empty -delete
      '';
    };

    #
    # Run documentation generator.
    #
    task_docs                                                = taskRunner.mkTask {
      name                                                   = "docs";
      dependencies                                           = with pkgs; [
        coreutils           # /bin/echo  # /bin/cp
      ];
      isolate                                                = false;
      src                                                    = with pkgs; ''
        ${coreutils}/bin/cp ./docs/README.md ./README.md
      '';
    };

    #
    # Run build for the project.
    #
    task_build                                                = taskRunner.mkTask {
      name                                                    = "build";
      dependencies                                            = with pkgs; [
        coreutils           # /bin/echo
        nix                 # /bin/nix
          git               # /bin/git
      ];
      src                                                     = with pkgs; ''
        ${nix}/bin/nix build \
          --experimental-features 'nix-command flakes' \
          --show-trace \
          --verbose \
          --option max-jobs 8 \
          --option cores 2 \
          --option eval-cache false \
          -L \
          "."
      '';
    };

    #
    # Run test for the project.
    #
    task_test                                                = taskRunner.mkTask {
      name                                                    = "test";
      dependencies                                            = with pkgs; [
        toolchain           # /bin/cargo
        pkg-config
        openssl
        gcc                       # TODO: We shouldn't need a direct reference to this?
      ];
      src                                                     = ''
        ${toolchain}/bin/cargo test
      '';
    };

    #
    # Run show info for the flake.
    #
    task_show                                                 = taskRunner.mkTask {
      name                                                    = "show";
      dependencies                                            = with pkgs; [
        task_build          # /bin/run
        coreutils           # /bin/echo
        nix                 # /bin/nix  /bin/nix-store
          git               # /bin/git
        jq                  # /bin/jq
        graphviz            # /bin/graphviz
      ];
      isolate                                                 = false;
      src                                                     = with pkgs; ''
        # Build
        ${task_build}/bin/build

        # Flake
        ${nix}/bin/nix flake show \
          --experimental-features 'nix-command flakes'

        # Outputs
        ${nix}/bin/nix derivation show | ${jq}/bin/jq '.[].outputs'

        # Store
        TASK_SHOW_NIX_STORE_PATH=$(${nix}/bin/nix eval --inputs-from . --raw)
        ${coreutils}/bin/echo "$TASK_SHOW_NIX_STORE_PATH"
        ${coreutils}/bin/echo ""

        # Dependencies
        ${nix}/bin/nix-store --query --tree       "$TASK_SHOW_NIX_STORE_PATH" | ${coreutils}/bin/cat
        ${coreutils}/bin/echo ""
        ${nix}/bin/nix-store --query --references "$TASK_SHOW_NIX_STORE_PATH" | ${coreutils}/bin/cat
        ${nix}/bin/nix-store --query --graph      "$TASK_SHOW_NIX_STORE_PATH" | ${graphviz}/bin/dot -Tpng -o result-dependencies.png 2> /dev/null
      '';
    };

    #
    # Run the project.
    #
    task_run                                                  = taskRunner.mkTask {
      name                                                    = "run";
      dependencies                                            = with pkgs; [
        coreutils           # /bin/echo
        nix                 # /bin/nix
          git               # /bin/git
      ];
      isolate                                                 = false;
      src                                                     = with pkgs; ''
        ${nix}/bin/nix run \
          --experimental-features 'nix-command flakes' \
          --show-trace \
          --verbose \
          --option eval-cache false \
          -L \
          "." -- $@
      '';
    };
  in (
    taskRunner.mkTaskRunner {
      dependencies                                       = with pkgs; [
        toolchain
        pkg-config
        openssl
      ];
      src                                                = ''
        export RUST_BACKTRACE=1
      '';
      tasks                                              = {
        help                                             = task_help;
        clean                                            = task_clean;
        docs                                             = task_docs;
        build                                            = task_build;
        test                                             = task_test;
        show                                             = task_show;
        run                                              = task_run;
      };
    }
  )
)


