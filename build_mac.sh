#!/bin/bash

echo ""
echo "======================================================="
echo " Build: CSV / Excel -> GitHub Uploader  (macOS)"
echo "======================================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# ── Architettura nativa ───────────────────────────────────────
ARCH=$(uname -m)
echo "[INFO] Architettura macchina: $ARCH"
export PYINSTALLER_TARGET_ARCH="$ARCH"
echo ""

# ── Installa python-tk via Homebrew (fornisce _tkinter.so) ────
# Necessario anche con Python da Homebrew: tcl-tk deve essere linkato
echo "[0/4] Verifica tcl-tk / python-tk via Homebrew..."
if command -v brew &>/dev/null; then
    # Installa tcl-tk se manca
    if ! brew list tcl-tk &>/dev/null 2>&1; then
        echo "  -> Installazione tcl-tk..."
        brew install tcl-tk --quiet
    else
        echo "  -> tcl-tk gia' installato."
    fi

    # Installa python-tk per la versione di Python attiva
    PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "3.13")
    if ! brew list "python-tk@${PY_VER}" &>/dev/null 2>&1; then
        echo "  -> Installazione python-tk@${PY_VER}..."
        brew install "python-tk@${PY_VER}" --quiet 2>/dev/null || \
        brew install python-tk --quiet 2>/dev/null || \
        echo "  [WARN] python-tk non installato via brew — si tenta comunque."
    else
        echo "  -> python-tk@${PY_VER} gia' installato."
    fi
else
    echo "  [WARN] Homebrew non trovato — salto installazione tcl-tk."
fi
echo ""

# ── Trova Python ──────────────────────────────────────────────
PYTHON=""
for candidate in \
    "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3" \
    "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3" \
    "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3" \
    "/opt/homebrew/bin/python3.13" \
    "/opt/homebrew/bin/python3.12" \
    "/opt/homebrew/bin/python3.11" \
    "/opt/homebrew/bin/python3" \
    "$(command -v python3 2>/dev/null)"; do
    [ -z "$candidate" ] && continue
    [ -f "$candidate" ] || continue
    if "$candidate" --version &>/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "[ERRORE] Python non trovato."
    echo "Scaricalo da: https://www.python.org/downloads/macos/"
    exit 1
fi
echo "[OK] Python: $PYTHON ($($PYTHON --version))"

# Verifica che tkinter sia disponibile nel Python scelto
echo "[INFO] Verifica tkinter..."
if ! "$PYTHON" -c "import tkinter" &>/dev/null 2>&1; then
    echo ""
    echo "[ERRORE] tkinter non disponibile in $PYTHON"
    echo ""
    echo "  Soluzioni:"
    echo "  1) Se usi Homebrew Python, esegui:"
    echo "     brew install python-tk@$(${PYTHON} -c 'import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")')"
    echo "     e poi rilancia questo script."
    echo ""
    echo "  2) Oppure installa Python UFFICIALE da:"
    echo "     https://www.python.org/downloads/macos/"
    echo "     (include tkinter di default)"
    echo ""
    exit 1
fi
echo "[OK] tkinter disponibile."
echo ""

# ── Virtualenv isolato ────────────────────────────────────────
VENV_DIR="$SCRIPT_DIR/.venv_build"
echo "[1/4] Creazione virtualenv in .venv_build ..."
rm -rf "$VENV_DIR"

# --system-site-packages permette al venv di vedere _tkinter.so installato da brew
"$PYTHON" -m venv "$VENV_DIR" --system-site-packages

VENV_PYTHON="$VENV_DIR/bin/python3"
VENV_PIP="$VENV_DIR/bin/pip"

# Verifica che tkinter sia visibile anche nel venv
if ! "$VENV_PYTHON" -c "import tkinter" &>/dev/null 2>&1; then
    echo "[WARN] tkinter non visibile nel venv — ricreo senza --system-site-packages"
    rm -rf "$VENV_DIR"
    "$PYTHON" -m venv "$VENV_DIR"
    VENV_PYTHON="$VENV_DIR/bin/python3"
    VENV_PIP="$VENV_DIR/bin/pip"
fi

echo "[OK] Virtualenv creato."
echo ""

# ── Dipendenze ────────────────────────────────────────────────
echo "[2/4] Installazione dipendenze..."
"$VENV_PIP" install --upgrade pip --quiet
"$VENV_PIP" install customtkinter pandas openpyxl PyGithub pyinstaller --quiet
echo "[OK] Dipendenze installate."
echo ""

# ── Pulizia ───────────────────────────────────────────────────
echo "[3/4] Pulizia build precedente..."
rm -rf build dist
echo "[OK] Pulizia completata."
echo ""

# ── Build ─────────────────────────────────────────────────────
echo "[4/4] Compilazione (3-6 minuti)..."
echo "[INFO] target_arch: $PYINSTALLER_TARGET_ARCH"
echo ""

export PYINSTALLER_TARGET_ARCH
"$VENV_PYTHON" -m PyInstaller app.spec --noconfirm --clean

if [ ! -d "dist/CSVGitHubUploader.app" ]; then
    echo ""
    echo "[ERRORE] .app non trovata."
    echo ""
    echo "Per debug:"
    echo "  $VENV_PYTHON -m PyInstaller app.spec --noconfirm --clean --log-level DEBUG 2>&1 | tee build_debug.log"
    exit 1
fi

chmod +x "dist/CSVGitHubUploader.app/Contents/MacOS/CSVGitHubUploader"
xattr -cr "dist/CSVGitHubUploader.app" 2>/dev/null || true

BUILT_ARCH=$(lipo -archs "dist/CSVGitHubUploader.app/Contents/MacOS/CSVGitHubUploader" 2>/dev/null || echo "N/A")
SIZE=$(du -sh "dist/CSVGitHubUploader.app" | cut -f1)

echo ""
echo "======================================================="
echo " BUILD COMPLETATA!"
echo " Architettura: $BUILT_ARCH"
echo " File: dist/CSVGitHubUploader.app  ($SIZE)"
echo ""
echo " TEST rapido dal terminale:"
echo "   ./dist/CSVGitHubUploader.app/Contents/MacOS/CSVGitHubUploader"
echo ""
echo " Per distribuire: zippa dist/CSVGitHubUploader.app"
echo "======================================================="
echo ""

open dist/ 2>/dev/null || true
