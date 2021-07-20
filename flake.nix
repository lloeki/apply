{
  description = "Simple zero-dependency tool to provision *nix machines";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) stdenv lib;

      in rec {
        defaultPackage = self.packages."${system}".apply;
        packages.apply = stdenv.mkDerivation {
          pname = "apply";
          version = "2021-07-16";

          src = ./.;

          nativeBuildInputs = with pkgs; [ makeWrapper ];

          # Overridden in tests
          doCheck = false;
          checkInputs = with pkgs; [
            shellcheck
            gnumake

            bash
            dash
            ksh

            # busybox as an input will break things
          ];

          # Test with each shell
          checkPhase = ''
            cd "$src"
            make test

            (
              export PATH="${lib.makeBinPath (with pkgs; [ busybox gnumake shellcheck ])}"
              make test-ash
            )
          '';

          # Don't patch shebangs on everything or it'll get the 'lib' and 'run'
          # scripts, which we need to be able to copy elsewhere.
          dontPatchShebangs = true;

          installPhase = ''
            mkdir -p $out/bin/
            cp ./{apply,lib,push,run} $out/bin/
            chmod +x $out/bin/*
          '';

          postFixup = ''
            for f in $out/bin/{apply,push}; do
              patchShebangs "$f"
              wrapProgram "$f" \
                --suffix PATH ":" "${lib.makeBinPath (with pkgs; [ coreutils parallel openssh ])}"
            done
          '';

          meta = with lib; {
            homepage = "https://github.com/andrew-d/apply";
            description = "TODO";
            maintainers = with maintainers; [ andrew-d ];
            license = licenses.bsd3;
            platforms = platforms.unix;
          };
        };

        defaultApp = self.apps."${system}".apply;
        apps.apply = {
          type = "app";
          program = "${self.defaultPackage."${system}"}/bin/apply";
        };

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

        checks = {
          apply = self.defaultPackage.${system}.overrideAttrs (super: { doCheck = true; });
        };
      }
    );
}
