# -*- mode: python ; coding: utf-8 -*-
import sys, os
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

ctk_datas = collect_data_files('customtkinter')

# Tkinter hidden imports solo su Windows (su Mac con Homebrew non esistono come moduli separati)
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
    hidden += ['tkinter', 'tkinter.ttk', 'tkinter.filedialog', 'tkinter.messagebox']

a = Analysis(
    ['app.py'],
    pathex=['.'],
    binaries=[],
    datas=ctk_datas,
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
    # Legge architettura dalla env var impostata da build_mac.sh
    # Se non presente usa quella nativa della macchina corrente
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
