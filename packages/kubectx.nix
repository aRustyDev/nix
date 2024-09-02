# https://elatov.github.io/2022/01/building-a-nix-package/
# https://nix-tutorial.gitlabpages.inria.fr/nix-tutorial/first-package.html
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md
# nix-shell kubectx.nix --command 'mkdir build && cd build && cmake .. && make'
{
  pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/4fe8d07066f6ea82cda2b0c9ae7aee59b2d241b3.tar.gz";
    sha256 = "sha256:06jzngg5jm1f81sc4xfskvvgjy5bblz51xpl788mnps1wrkykfhp";
  }) {}
}:
pkgs.stdenv.mkDerivation rec {
  pname = "chord";
  version = "0.1.0";

  src = pkgs.fetchgit {
    url = "https://gitlab.inria.fr/nix-tutorial/chord-tuto-nix-2022";
    rev = "069d2a5bfa4c4024063c25551d5201aeaf921cb3";
    sha256 = "sha256-MlqJOoMSRuYeG+jl8DFgcNnpEyeRgDCK2JlN9pOqBWA=";
  };

  doCheck = false;

  passThru.tests.version = testVersion{ package = pkgs.chord; };
  passThru.tests.test = {
    name = "test";
    help = "test";
    checkPhase = ''
      echo "test"
    '';
  };

  meta = with lib; {
    description = "A tool for managing multiple clusters";
    longDescription = "A tool for managing multiple clusters";
    homepage = "https://gitlab.inria.fr/nix-tutorial/chord-tuto-nix-2022";
    changelog = "https://gitlab.inria.fr/nix-tutorial/chord-tuto-nix-2022/blob/master/CHANGELOG.md";
    license = licenses.gpl3;
    maintainers = with maintainers; [ mic92 ];
    platforms = platforms.linux;
  };

  buildInputs = [
    pkgs.simgrid
    pkgs.boost
    pkgs.cmake
  ];

  configurePhase = ''
    cmake .
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv chord $out/bin
  '';
}
