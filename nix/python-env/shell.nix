# Python interpreter environment for use with direnv
#
# Provides only the Python interpreter - packages are installed via uv.
# This ensures version specifiers in requirements.txt/pyproject.toml are respected.
#
# Usage in .envrc:
#   use_python_env           # Normal mode with activation message
#   use_python_env --quiet   # Suppress activation message
#
# The function will:
# 1. Read Python version from mise config (.mise.toml or .tool-versions)
# 2. Provide Python interpreter from nixpkgs (or mise if version not in nixpkgs)
# 3. Use uv to create venv and install packages from PyPI
#
# See: nix/modules/home/direnv.nix for the use_python_env implementation
{ pkgs ? import <nixpkgs> {}
, quiet ? false  # Suppress activation message
, pythonVersion ? ""  # Python version like "311", "312", "313" (empty = default python3)
}:

let
  # Map pythonVersion to nixpkgs python package
  # Empty string or invalid version falls back to python3
  pythonVersionMap = {
    "310" = pkgs.python310;
    "311" = pkgs.python311;
    "312" = pkgs.python312;
    "313" = pkgs.python313;
  };

  my-python =
    if pythonVersion != "" && builtins.hasAttr pythonVersion pythonVersionMap
    then pythonVersionMap.${pythonVersion}
    else pkgs.python3;
in
pkgs.mkShell {
  name = "python-env";

  buildInputs = [ my-python pkgs.uv ];

  shellHook = ''
    ${if !quiet then ''
    echo "🐍 Python ${my-python.version} from nixpkgs"
    '' else ""}
  '';
}
