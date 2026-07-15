#!/usr/bin/env bash
# Installs the Python dependencies WMH_QC.py needs (numpy, pillow, nibabel)
# into a dedicated virtualenv, so it doesn't depend on whatever happens to
# be in your base/conda environment.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

if ! command -v python3 &>/dev/null; then
    echo "python3 not found. Install Python 3 first." >&2
    exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment at $VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install numpy pillow nibabel

echo
echo "Dependencies installed."
echo "Run WMH_QC.py with:"
echo "  $VENV_DIR/bin/python $SCRIPT_DIR/WMH_QC.py --root ... "
