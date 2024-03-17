{
  description = "Build Android (AOSP) using Nix";
  inputs = {
    nixpkgs.url = "flake:nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    androidPkgs.url = "github:tadfisher/android-nixpkgs/stable";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
        # inputs.devenv.flakeModule
        inputs.treefmt-nix.flakeModule

      ];
      flake = {
        # Put your original flake attributes here.
      };
      #systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-linux"
      ];
      # perSystem = { config, self', inputs', pkgs, system, ... }: {
      perSystem = { config, pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.androidPkgs.overlays.default
            # outputs.overlays.pkgs-sets-unstable
          ];
          config = { };
        };

        packages = {

          inherit ((import ./docs { inherit pkgs; })) manual;
          inherit (import ./apks { inherit pkgs; }) auditor; # bromite chromium seedvault_10;
        };

        devShells.default =
          let
            sdk = pkgs.androidSdk (p: with p; [ cmdline-tools-latest platform-tools platforms-android-34 build-tools-34-0-0 ]);
          in
          pkgs.mkShell {
            name = "robotnix-scripts";
            JAVA_HOME = "${pkgs.jdk}";

            ANDROID_HOME = "${sdk}/share/android-sdk";
            nativeBuildInputs = with pkgs; [
              # For android updater scripts
              (python3.withPackages (p: with p; [ mypy flake8 pytest ]))
              gitRepo
              nix-prefetch-git
              curl
              pup
              jq
              shellcheck
              wget

              gradle
              jdk

              # For chromium updater script
              # python2 cipd git # -python2 is EOL.

              cachix
            ];
            PYTHONPATH = ./scripts;
            shellHook = ''
              # export DEBUG=1
              ${config.pre-commit.installationScript}
            '';
          };
        pre-commit = {
          check.enable = true;
          settings.settings = {
            deadnix.edit = true;
          };
          settings.hooks = {
            actionlint.enable = true;
            treefmt.enable = true;
          };
        };
        treefmt.projectRootFile = ./flake.nix;
        treefmt.programs = {
          nixpkgs-fmt.enable = true;
          yamlfmt.enable = true;
          shfmt.enable = true;
          mdformat.enable = true;
          statix.enable = true;
          deadnix.enable = true;
        };
      };
    };
}
