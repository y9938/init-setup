#!/home/k/scripts/venv/bin/python3

import os
import re
from mutagen.id3 import ID3, TPE2, TALB, TYER
from mutagen.mp3 import MP3
import sys

# Default values
DIRECTORY = "/home/k/music"
VERBOSE = False


def show_help():
    print("Usage: music_manager.py [options] [directory]")
    print("Options:")
    print("  -h, --help     Show this help message")
    print("  -v, --verbose  Enable verbose output")
    print("\nExample: python music_manager.py /path/to/directory")


def set_album_artist(artist_name):
    """Set the Album Artist tag for all MP3 files in the directory."""
    for file_name in os.listdir(DIRECTORY):
        if file_name.endswith(".mp3"):
            file_path = os.path.join(DIRECTORY, file_name)
            audio = MP3(file_path, ID3=ID3)
            audio.tags.add(TPE2(encoding=3, text=artist_name))  # Add Album Artist tag
            audio.save()
            if VERBOSE:
                print(f"Album Artist is set to '{artist_name}' for file '{file_name}'.")


def set_album_and_year(album_name, year, start_num, end_num=None):
    """Set the Album and Year tags for a range of MP3 files."""
    if end_num is None:
        end_num = start_num  # Treat as a single file if no end number is provided

    for num in range(start_num, end_num + 1):
        file_num = f"{num:03d}"
        for file_name in os.listdir(DIRECTORY):
            if file_name.startswith(file_num) and file_name.endswith(".mp3"):
                file_path = os.path.join(DIRECTORY, file_name)
                audio = MP3(file_path, ID3=ID3)
                audio.tags.add(TALB(encoding=3, text=album_name))  # Add Album tag
                audio.tags.add(TYER(encoding=3, text=str(year)))  # Add Year tag
                audio.save()
                if VERBOSE:
                    print(
                        f"Set Album to '{album_name}' and Year to '{year}' for file '{file_name}'."
                    )


def rename_files():
    """Rename MP3 files by increasing their prefix starting from the chosen one."""
    files = [f for f in os.listdir(DIRECTORY) if f.endswith(".mp3")]
    files.sort()
    for i, file_name in enumerate(files):
        print(f"{i + 1}) {file_name}")
    choice = int(input("Enter the file number to keep with its prefix: "))
    chosen_file = files[choice - 1]
    chosen_prefix = chosen_file[:3]
    print(f"You chose: {chosen_file} with prefix: {chosen_prefix}")

    # Обновление регулярного выражения для обработки числовых префиксов
    prefix_pattern = r"^(\d{3})_.*\.mp3$"  # Регулярное выражение для числовых префиксов

    # Составляем список файлов, которые нужно переименовать
    files_to_rename = []

    for file_name in files:
        match = re.match(prefix_pattern, file_name)
        if match:
            current_prefix = match.group(1)
            if int(current_prefix) >= int(
                chosen_prefix
            ):  # Файлы с префиксом >= выбранного
                if file_name != chosen_file:
                    files_to_rename.append(file_name)

    # Переименовываем файлы
    for file_name in files_to_rename:
        current_prefix = int(file_name[:3])
        new_prefix = current_prefix + 1
        remaining_part = file_name[3:]
        new_file_name = f"{new_prefix:03d}{remaining_part}"

        old_file_path = os.path.join(DIRECTORY, file_name)
        new_file_path = os.path.join(DIRECTORY, new_file_name)
        os.rename(old_file_path, new_file_path)
        if VERBOSE:
            print(f"Renamed: {file_name} -> {new_file_name}")


def main():
    global VERBOSE
    if len(sys.argv) > 1:
        if sys.argv[1] in ["-h", "--help"]:
            show_help()
            return
        elif sys.argv[1] in ["-v", "--verbose"]:
            VERBOSE = True
            sys.argv.pop(1)
        else:
            global DIRECTORY
            DIRECTORY = sys.argv[1]

    print("Choose an action:")
    print("1) Set Album Artist")
    print("2) Set Album and Year")
    print("3) Rename Files and Adjust Numbering")
    action = input("Enter choice: ")

    if action == "1":
        artist_name = input("Enter Album Artist name: ")
        set_album_artist(artist_name)
    elif action == "2":
        album_name = input("Enter album title: ")
        year = input("Enter the release year: ")
        start_num = int(input("Enter the starting file number (e.g., 001): "))
        end_num_input = input(
            "Enter the ending file number (e.g., 014) or press Enter for SINGLE: "
        )
        end_num = int(end_num_input) if end_num_input.strip() else None
        set_album_and_year(album_name, year, start_num, end_num)
    elif action == "3":
        rename_files()
    else:
        print("Wrong choice. Please select 1, 2, or 3.")


if __name__ == "__main__":
    main()
