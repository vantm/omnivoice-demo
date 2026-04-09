{
  description = "Omnivoice Demo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    systems.url = "github:nix-systems/x86_64-linux";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos-cuda.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
            cudaVersion = "12";
          };
        };
      in
      {
        devShell =
          pkgs.mkShell.override
            {
              stdenv = pkgs.gcc13Stdenv;
            }
            {
              buildInputs = with pkgs; [
                python3Packages.venvShellHook
                ffmpeg
                cudatoolkit
                cudaPackages.cudnn
                cudaPackages.cuda_cudart
              ];

              venvDir = ".venv";

              CUDA_PATH = pkgs.cudatoolkit;

              LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
                (with pkgs; [
                  stdenv.cc.cc.lib
                  cudatoolkit
                  ffmpeg
                ])
                ++ [
                  "/run/opengl-driver"
                ]
              );
            };
      }
    );
}
