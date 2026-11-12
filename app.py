# -*- mode: python ; coding: utf-8 -*-
import sys, os, glob
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

ctk_datas = collect_data_files('customtkinter')

# Su macOS cerca _tkinter.so e i framework tcl/tk da includere nel bundle
extra_binaries = []
extra_datas    = []

if sys.platform != 'win32':
    # Cerca _tkinter.so (può stare in posti diversi a seconda di come è installato Python)
    tk_so_patterns = [
        '/opt/homebrew/lib/python3*/lib-dynload/_tkinter*.so',
        '/opt/homebrew/Cellar/python*/*/lib/python3*/lib-dynload/_tkinter*.so',
        '/Library/Frameworks/Python.framework/**/lib-dynload/_tkinter*.so',
        '/usr/lib/python3*/_tkinter*.so',
    ]
    for pattern in tk_so_patterns:
        matches = glob.glob(pattern, recursive=True)
        if matches:
            extra_binaries.append((matches[0], '.'))
            print(f"[spec] Found _tkinter: {matches[0]}")
            break

    # Cerca le librerie tcl/tk (necessarie a runtime)
    tcl_patterns = [
        '/opt/homebrew/opt/tcl-tk/lib/libtcl*.dylib',
        '/opt/homebrew/opt/tcl-tk@8/lib/libtcl*.dylib',
        '/usr/lib/libtcl*.dylib',
    ]
    tk_patterns = [
        '/opt/homebrew/opt/tcl-tk/lib/libtk*.dylib',
        '/opt/homebrew/opt/tcl-tk@8/lib/libtk*.dylib',
        '/usr/lib/libtk*.dylib',
    ]
    for pattern in tcl_patterns + tk_patterns:
        for match in glob.glob(pattern):
            extra_binaries.append((match, '.'))
            print(f"[spec] Found tcl/tk lib: {match}")

    # Cerca i data directory di tcl/tk (temi, encoding, ecc.)
    tcl_data_patterns = [
        '/opt/homebrew/opt/tcl-tk/lib/tcl8*',
        '/opt/homebrew/opt/tcl-tk@8/lib/tcl8*',
        '/opt/homebrew/opt/tcl-tk/lib/tk8*',
        '/opt/homebrew/opt/tcl-tk@8/lib/tk8*',
    ]
    for pattern in tcl_data_patterns:
        for match in glob.glob(pattern):
            if os.path.isdir(match):
                dirname = os.path.basename(match)
                extra_datas.append((match, dirname))
                print(f"[spec] Found tcl/tk data: {match}")

hidden = [
    'customtkinter',
    'github',
    'github.GithubException',
    'pandas',
    'openpyxl',
    'openpyxl.styles',
    'openpyxl.utils',
    'openpyxl.workbook',
]

if sys.platform == 'win32':
    hidden += ['tkinter', 'tkinter.ttk', 'tkinter.filedialog', 'tkinter.messagebox', '_tkinter']

a = Analysis(
    ['app.py'],
    pathex=['.'],
    binaries=extra_binaries,
    datas=ctk_datas + extra_datas,
    hiddenimports=hidden,
    hookspath=['.'],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['matplotlib', 'scipy', 'IPython', 'pytest', 'setuptools', 'distutils'],
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# ── Windows: singolo .exe ──────────────────────────────────────
if sys.platform == 'win32':
    exe = EXE(
        pyz, a.scripts, a.binaries, a.zipfiles, a.datas, [],
        name='CSVGitHubUploader',
        debug=False,
        strip=False,
        upx=True,
        runtime_tmpdir=None,
        console=False,
        icon='icon.ico' if os.path.exists('icon.ico') else None,
    )

# ── macOS: .app bundle ────────────────────────────────────────
else:
    import platform as _platform
    _target_arch = os.environ.get('PYINSTALLER_TARGET_ARCH', _platform.machine())
    print(f"[spec] target_arch = {_target_arch}")

    exe = EXE(
        pyz, a.scripts, [],
        exclude_binaries=True,
        name='CSVGitHubUploader',
        debug=False,
        strip=False,
        upx=False,
        console=False,
        argv_emulation=False,
        target_arch=_target_arch,
        codesign_identity=None,
        icon='icon.icns' if os.path.exists('icon.icns') else None,
    )
    coll = COLLECT(
        exe, a.binaries, a.zipfiles, a.datas,
        strip=False,
        upx=False,
        name='CSVGitHubUploader',
    )
    app = BUNDLE(
        coll,
        name='CSVGitHubUploader.app',
        icon='icon.icns' if os.path.exists('icon.icns') else None,
        bundle_identifier='it.dtd.csv-github-uploader',
        info_plist={
            'NSPrincipalClass': 'NSApplication',
            'NSAppleScriptEnabled': False,
            'NSHighResolutionCapable': True,
            'CFBundleShortVersionString': '1.0.0',
            'LSMinimumSystemVersion': '11.0',
        },
    )
