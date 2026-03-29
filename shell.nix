{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.setuptools
    pkgs.git
    pkgs.wget
  ];

  shellHook = ''
    export PIP_PREFIX="$HOME/.local"
    export PATH="$HOME/.local/bin:$PATH"
    echo "DFIR lab shell ready. Run: pip install volatility3 --user"
  '';
}
