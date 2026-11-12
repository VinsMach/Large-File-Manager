# hook-customtkinter.py
# Hook locale PyInstaller — assicura che customtkinter trovi
# tutti i suoi asset e che tkinter sia incluso correttamente.

from PyInstaller.utils.hooks import collect_data_files, collect_submodules

datas    = collect_data_files('customtkinter')
hiddenimports = collect_submodules('customtkinter')
