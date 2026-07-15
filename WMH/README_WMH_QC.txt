WMH_QC.py -- Setup and Usage Guide
====================================

WMH_QC.py generates FLAIR+WMH overlay JPEGs (grid of axial slices) for
quick visual QC of white matter hyperintensity segmentations.

Files in this folder you need:
  - WMH_QC.py                    the QC script
  - install_WMH_QC_deps.sh       one-time dependency installer


1. PREREQUISITES
-----------------
- Python 3 must already be installed and on PATH (check with: python3 --version).
- Internet access is needed the first time you run the install script
  (it downloads packages from PyPI).


2. ONE-TIME SETUP: INSTALL DEPENDENCIES
-----------------------------------------
From a terminal, run:

    /path/to/WMH/install_WMH_QC_deps.sh

This creates a self-contained virtual environment at:

    /path/to/WMH/.venv

and installs the three packages WMH_QC.py needs: numpy, pillow, nibabel.
You only need to do this once per computer. If you re-run it later, it
will reuse the existing .venv and just make sure packages are up to date.

You do NOT need to activate the venv or modify your shell profile. You
always call the venv's Python directly, as shown below.


3. DIRECTORY LAYOUT WMH_QC.py EXPECTS
----------------------------------------
Two supported layouts:

  Multi timepoint (default):
    <ROOT>/<TIMEPOINT>/<SUBJECT>/<flair file>
    <ROOT>/<TIMEPOINT>/<SUBJECT>/<wmh mask file>
    QC JPEGs written to <ROOT>/<TIMEPOINT>/QC_JPEGs/

  Single timepoint (--single-timepoint flag):
    <ROOT>/<SUBJECT>/<flair file>
    <ROOT>/<SUBJECT>/<wmh mask file>
    QC JPEGs written to <ROOT>/QC_JPEGs/

The FLAIR and WMH mask files do not need to match an exact filename --
the script tries an exact match first, then falls back to searching for
files matching common patterns (e.g. "*flair*.nii.gz" for FLAIR,
"*seg-lst*.nii.gz" / "*wmh*bin*.nii.gz" / "*mask*.nii.gz" for the WMH
mask). If it auto-detects a file, it prints which one it picked. If it
can't find a file, or finds more than one possible match, it prints a
WARNING and skips that subject rather than guessing -- check the
terminal output to confirm every subject you expected was processed.


4. RUNNING THE SCRIPT
------------------------
Always call the script using the venv's Python created in step 2:

    /path/to/WMH/.venv/bin/python /path/to/WMH/WMH_QC.py [options]

Example -- single timepoint, two named subjects:

    /path/to/WMH/.venv/bin/python /path/to/WMH/WMH_QC.py \
        --root /path/to/data_folder \
        --single-timepoint \
        --subjects sub-HD001 sub-HD002 \
        --out-dir /path/to/data_folder/QC_JPEGs

Example -- multi timepoint, auto-discover all subjects, default
timepoint folder names (BL, Y2, Y4Y5):

    /path/to/WMH/.venv/bin/python /path/to/WMH/WMH_QC.py \
        --root /path/to/data_folder

Example -- custom timepoint folder names:

    /path/to/WMH/.venv/bin/python /path/to/WMH/WMH_QC.py \
        --root /path/to/data_folder --timepoints BL Y2 Y4Y5

Example -- specify exact filenames instead of relying on auto-detection:

    /path/to/WMH/.venv/bin/python /path/to/WMH/WMH_QC.py \
        --root /path/to/data_folder --single-timepoint \
        --flair-name FLAIR.nii.gz --wmh-name WMH_bin.nii.gz

Useful options:
    --subjects NAME [NAME ...]   only process these subject folders
                                  (alias: --subject)
    --single-timepoint           use the ROOT/SUBJECT/* layout
    --timepoints NAME [NAME ...] custom timepoint folder names (multi mode)
    --flair-name NAME            exact FLAIR filename to look for first
    --wmh-name NAME               exact WMH mask filename to look for first
    --out-dir PATH               where to write the QC JPEGs
    --n-slices N                 number of axial slices in the grid (default 15)
    --ncols N                    number of grid columns (default 5)
    --alpha 0-1                  WMH overlay opacity (default 0.7)

Run with --help to see the full list:

    /path/to/WMH/.venv/bin/python /path/to/WMH/WMH_QC.py --help


5. SLICE SELECTION / WHAT YOU SHOULD SEE
--------------------------------------------
The grid of slices is centered on the WMH lesion mask's own extent
(padded a bit above/below), not on the raw volume. This keeps every
slice showing actual brain even though the FLAIR images are not
skull-stripped. If a subject has zero segmented lesions, the script
falls back to trimming the outer edges of the full volume, which is a
weaker heuristic and may include a few non-brain slices (sinuses,
skull base) at the edges.


6. TROUBLESHOOTING
----------------------
- "ModuleNotFoundError: No module named 'nibabel'"
    You are not using the venv's Python. Re-check step 4 -- the command
    must start with /path/to/WMH/.venv/bin/python, not plain "python3".

- "Root directory does not exist"
    Double check --root is an absolute path to the correct folder.

- A subject you expected doesn't show up in the output / "0 overlay(s)
  generated"
    Look for a WARNING line above it in the terminal output -- it means
    the FLAIR or WMH file couldn't be found or was ambiguous for that
    subject. Pass --flair-name / --wmh-name explicitly to fix it.
