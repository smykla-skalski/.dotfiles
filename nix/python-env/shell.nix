{ pkgs ? import <nixpkgs> {} }:

let
  my-python = pkgs.python3;
  python-with-packages = my-python.withPackages (ps: with ps; [
    pillow    # Python Imaging Library (PIL fork)
    pyyaml    # YAML parser and emitter
  ]);
in
pkgs.mkShell {
  name = "projects-python-env";

  buildInputs = [ python-with-packages ];

  shellHook = ''
    # Fix PYTHONPATH to include nix packages
    # See: https://github.com/NixOS/nixpkgs/issues/61144
    PYTHONPATH=${python-with-packages}/${python-with-packages.sitePackages}
    export PYTHONPATH

    echo "🐍 Python environment activated"
    echo "   Python: $(python3 --version)"
    echo "   Packages: Pillow, PyYAML"
  '';
}
