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

  # Building out-of-tree kernel modules
  # To further extend Bottlerocket, you may want to build extra kernel modules.
  # The specifics of building an out-of-tree module will vary by project, but the first
  # step is to download the "kmod kit" that contains the kernel headers and toolchain
  # you'll need to use.
  # https://github.com/bottlerocket-os/bottlerocket/blob/develop/QUICKSTART-EKS.md
  # https://github.com/bottlerocket-os/bottlerocket/blob/develop/QUICKSTART-LOCAL.md
  buildInputs = [
    pkgs.cargo
    pkgs.boost
    pkgs.cmake
    pkgs.docker
  ];

  configurePhase = ''
    cargo install tuftool
    cargo install cargo-make
    cargo make -e BUILDSYS_VARIANT=my-variant

    curl -O "https://cache.bottlerocket.aws/root.json"
    sha512sum -c <<<"2ff1fbf99b20dd7ff5d2c84243a8e3b51701183b1f524b7d470a6b7a9b0172fbb36a0949b7e586ab7ccb6e348eb77125d6ed9fd1a638f4381e4f3f084ff38596  root.json"

    ARCH=x86_64
    VERSION=v1.11.0
    VARIANT=aws-k8s-1.24
    OUTDIR="${VARIANT}-${VERSION}"

    tuftool download "${OUTDIR}" --target-name ${VARIANT}-${ARCH}-kmod-kit-${VERSION}.tar.xz \
      --root ./root.json \
      --metadata-url "https://updates.bottlerocket.aws/2020-07-07/${VARIANT}/${ARCH}/" \
      --targets-url "https://updates.bottlerocket.aws/targets/"

    tar xf "${VARIANT}-${ARCH}-kmod-kit-${VERSION}.tar.xz"

    export CROSS_COMPILE="${ARCH}-bottlerocket-linux-musl-"
    export KERNELDIR="${PWD}/${VARIANT}-${ARCH}-kmod-kit-${VERSION}/kernel-devel"
    export PATH="${PWD}/${VARIANT}-${ARCH}-kmod-kit-${VERSION}/toolchain/usr/bin:${PATH}"
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv chord $out/bin
  '';
}
