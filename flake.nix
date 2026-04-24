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
        runtimeInputs = with pkgs; [
          yt-dlp
          ffmpeg
        ];
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
                (pkgs.writeShellApplication {
                  inherit runtimeInputs;
                  name = "trimaudio";
                  text = ''
                    INPUT="$1"
                    shift
                    FROM="$1"
                    shift
                    TO="$1"
                    if [ ! -f "$INPUT" ] ; then
                      echo File not found
                      exit 1;
                    fi
                    if [ -z "$FROM" ] ; then
                      echo Start time must be provided
                      exit 1;
                    fi
                    if [ -z "$TO" ] ; then
                      echo End time must be provided
                      exit 1;
                    fi
                    TEMP="tmp-$(basename "$INPUT")"
                    mv "$INPUT" "$TEMP"
                    ffmpeg -i "$TEMP" -ss "$FROM" -to "$TO" -c copy "$INPUT"
                    rm "$TEMP"
                  '';
                })
                (pkgs.writeShellApplication {
                  inherit runtimeInputs;
                  name = "getaudio";
                  text = ''
                    URL="$1"
                    shift
                    NAME="''${1:-output}"
                    if [ -z "$URL" ] ; then
                      echo The URL is required
                      exit 1
                    fi
                    yt-dlp -t mp3 --audio-quality 0 "$URL" -o "$NAME.mp3"
                  '';
                })
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
