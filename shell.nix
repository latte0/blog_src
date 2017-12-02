let
  pkgs = import (import ./fetch-nixpkgs.nix) {};
in
  { ghc ? pkgs.haskell.compiler.ghc822 }:
  pkgs.haskell.lib.buildStackProject {
    inherit ghc;
    name = "blog";
    buildInputs = with pkgs; [
      glpk
      pcre
      zlib
      nodejs-9_x
      coreutils
    ];
  }
