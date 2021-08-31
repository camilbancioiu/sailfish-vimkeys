#!/usr/bin/env python3

import sys
from pathlib import Path
import shutil

SRC_ROOT = Path('/home/nemo/Source/vimkeys')
DEST_ROOT = Path('/usr/share/maliit/plugins/com/jolla')
BACKUP_ROOT = Path('/home/nemo/.vimkeys_backup')

FILES_TO_BACKUP = [
    'InputHandler.qml'
]

FILES_TO_COPY = [
    'InputHandler.qml'
]

FOLDERS_TO_COPY = [
    'vimkeys'
]


def main():
    command = sys.argv[1]
    if command == 'a' or command == 'apply':
        apply()
    if command == 'u' or command == 'unapply':
        unapply()


def apply():
    print('Applying patch...')
    create_backup(FILES_TO_BACKUP)
    copy_src_to_dest(FILES_TO_COPY, FOLDERS_TO_COPY)


def unapply():
    print('Unapplying patch...')
    delete_copied_files_and_folders(FILES_TO_COPY, FOLDERS_TO_COPY)
    restore_backup(FILES_TO_BACKUP)


def create_backup(files):
    BACKUP_ROOT.mkdir(parents=True, exist_ok=True)
    for file in files:
        shutil.move(str(SRC_ROOT / file), str(BACKUP_ROOT))
        print(f'Moved file {SRC_ROOT / file} to {BACKUP_ROOT}')


def copy_src_to_dest(files, folders):
    for file in files:
        shutil.copy(SRC_ROOT / file, DEST_ROOT)
        print(f'Copied file {SRC_ROOT / file} to {DEST_ROOT}')
    for folder in folders:
        shutil.copytree(SRC_ROOT / folder, DEST_ROOT)
        print(f'Copied folder {SRC_ROOT / folder} to {DEST_ROOT}')


def delete_copied_files_and_folders(files, folders):
    for file in files:
        (DEST_ROOT / file).unlink()
        print(f'Deleted file {DEST_ROOT / file}')
    for folder in folders:
        (DEST_ROOT / folder).rmdir()
        print(f'Deleted folder {DEST_ROOT / folder}')


def restore_backup(files):
    for file in files:
        shutil.copy(BACKUP_ROOT / file, DEST_ROOT)
        print(f'Copied backup file {BACKUP_ROOT / file} to {DEST_ROOT}')


if __name__ == '__main__':
    main()
