{
  description = "Simple zero-dependency tool to provision *nix machines";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Shells
            bash
            dash
            ksh

            # Tools
            gnumake
            shellcheck
          ];
        };

        checks = let
          commonDeps = with pkgs; [ gnumake shellcheck ];

        in {
          bash = pkgs.runCommand "lint" {
            src = ./.;
            nativeBuildInputs = commonDeps ++ (with pkgs; [ bash ]);
          } ''
            export SHELL="${pkgs.bash}/bin/bash"
            make -C "$src" test-bash
            touch "$out"
          '';

          dash = pkgs.runCommand "lint" {
            src = ./.;
            nativeBuildInputs = commonDeps ++ (with pkgs; [ dash ]);
          } ''
            export SHELL="${pkgs.dash}/bin/dash"
            make -C "$src" test-dash
            touch "$out"
          '';

          busybox = pkgs.runCommand "lint" {
            src = ./.;
            nativeBuildInputs = commonDeps ++ (with pkgs; [ busybox ]);
          } ''
            export SHELL="${pkgs.busybox}/bin/ash"
            make -C "$src" test-ash
            touch "$out"
          '';
        };
      }
    );
}
