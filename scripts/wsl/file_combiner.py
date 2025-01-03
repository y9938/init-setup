#!/usr/bin/env python3
import os
import sys
import argparse
from datetime import datetime
import fnmatch


class FileColorPrinter:
    """Minimalistic class for colored output"""

    # Basic colors
    SUCCESS = "\033[38;5;82m"
    ERROR = "\033[38;5;196m"
    INFO = "\033[38;5;75m"
    WARNING = "\033[38;5;214m"
    RESET = "\033[0m"

    @staticmethod
    def format_message(message, color=None):
        return f"{color}{message}{FileColorPrinter.RESET}" if color else message

    @staticmethod
    def print_success(message):
        print(FileColorPrinter.format_message(message, FileColorPrinter.SUCCESS))

    @staticmethod
    def print_error(message):
        print(FileColorPrinter.format_message(message, FileColorPrinter.ERROR))

    @staticmethod
    def print_info(message):
        print(FileColorPrinter.format_message(message, FileColorPrinter.INFO))

    @staticmethod
    def print_warning(message):
        print(FileColorPrinter.format_message(message, FileColorPrinter.WARNING))


DEFAULT_EXCLUDE_PATTERNS = [
    # Binary and executable files
    "*.exe",
    "*.dll",
    "*.so",
    "*.dylib",
    "*.bin",
    "*.o",
    # Images
    "*.jpg",
    "*.jpeg",
    "*.png",
    "*.gif",
    "*.bmp",
    "*.ico",
    "*.svg",
    "*.webp",
    # Audio and video
    "*.mp3",
    "*.wav",
    "*.ogg",
    "*.mp4",
    "*.avi",
    "*.mkv",
    "*.mov",
    # Archives
    "*.zip",
    "*.rar",
    "*.7z",
    "*.tar",
    "*.gz",
    "*.bz2",
    # System files and folders
    ".git/*",
    ".svn/*",
    ".hg/*",
    ".vscode/*",
    ".idea/*",
    "node_modules/*",
    "venv/*",
    "env/*",
    "__pycache__/*",
    # Documents and office files
    "*.pdf",
    "*.doc",
    "*.docx",
    "*.xls",
    "*.xlsx",
    "*.ppt",
    "*.pptx",
    # Fonts
    "*.ttf",
    "*.otf",
    "*.woff",
    "*.woff2",
    "*.eot",
    # Databases
    "*.db",
    "*.sqlite",
    "*.sqlite3",
    # Other binary formats
    "*.pyc",
    "*.pyo",
    "*.pyd",
    # Temporary files
    "*.tmp",
    "*.temp",
    "*.swp",
    "*.swo",
    "*~",
    # Localization and resource files
    "*.mo",
    "*.po",
]


def is_excluded(file_path, exclude_patterns):
    file_path = file_path.replace(os.sep, "/").removeprefix("./")
    matching_pattern = next(
        (
            pattern
            for pattern in exclude_patterns
            if fnmatch.fnmatch(file_path, pattern.replace(os.sep, "/"))
            or fnmatch.fnmatch(
                os.path.basename(file_path), pattern.replace(os.sep, "/")
            )
        ),
        None,
    )
    return matching_pattern


def get_file_extension(file_path):
    return os.path.splitext(file_path)[1][1:] or "txt"


def combine_files(
    paths,
    recursive=False,
    exclude_patterns=None,
    use_default_excludes=True,
    verbose=False,
    output_path=None,
):
    all_exclude_patterns = []
    if use_default_excludes:
        all_exclude_patterns.extend(DEFAULT_EXCLUDE_PATTERNS)
    if exclude_patterns:
        all_exclude_patterns.extend(exclude_patterns)

    if output_path:
        output_file = output_path
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
    else:
        directory = os.getcwd()
        timestamp = datetime.now().strftime("%H%M")
        output_file = os.path.join(directory, f"Combined-{timestamp}.txt")

    files_to_process = []
    excluded_files = []
    skipped_dirs = []
    processed_files = []
    failed_files = []

    # Process all provided paths
    for path in paths:
        if os.path.isdir(path):
            # Handle directory
            for root, _, files in (
                os.walk(path) if recursive else [(path, None, os.listdir(path))]
            ):
                for item in files:
                    full_path = os.path.join(root, item)
                    if full_path == output_file:
                        continue

                    # Handle directories in non-recursive mode
                    if not recursive and os.path.isdir(full_path):
                        if verbose:
                            FileColorPrinter.print_info(
                                f"Skipped directory: {full_path} (use -r for recursive mode)"
                            )
                        skipped_dirs.append(full_path)
                        continue

                    exclude_pattern = is_excluded(full_path, all_exclude_patterns)
                    if exclude_pattern:
                        if verbose:
                            FileColorPrinter.print_warning(
                                f"Skipped: {full_path} (matched pattern: {exclude_pattern})"
                            )
                        excluded_files.append((full_path, exclude_pattern))
                        continue

                    files_to_process.append(full_path)
                    if verbose:
                        FileColorPrinter.print_info(f"Queued: {full_path}")
        else:
            # Handle single file
            if os.path.isfile(path):
                exclude_pattern = is_excluded(path, all_exclude_patterns)
                if exclude_pattern:
                    if verbose:
                        FileColorPrinter.print_warning(
                            f"Skipped: {path} (matched pattern: {exclude_pattern})"
                        )
                    excluded_files.append((path, exclude_pattern))
                    continue

                files_to_process.append(path)
                if verbose:
                    FileColorPrinter.print_info(f"Queued: {path}")
            else:
                if verbose:
                    FileColorPrinter.print_warning(f"Path not found: {path}")
                failed_files.append((path, "File not found"))

    files_to_process = list(dict.fromkeys(files_to_process))  # Remove duplicates
    files_to_process.sort()

    # Process files
    with open(output_file, "w", encoding="utf-8") as outfile:
        for file_path in files_to_process:
            try:
                with open(file_path, "r", encoding="utf-8", errors="replace") as infile:
                    outfile.write(
                        f"\n{file_path}\n```{get_file_extension(file_path)}\n"
                    )
                    outfile.write(infile.read())
                    outfile.write("\n```\n")
                processed_files.append(file_path)
                if verbose:
                    FileColorPrinter.print_success(f"Processed: {file_path}")
            except Exception as e:
                failed_files.append((file_path, str(e)))
                FileColorPrinter.print_error(f"Error processing {file_path}: {str(e)}")

    # Print summary
    if verbose:
        print("\nSummary:")
        print(
            f"Total items found: {len(files_to_process) + len(excluded_files) + len(skipped_dirs)}"
        )
        print(f"Successfully processed: {len(processed_files)}")
        print(f"Excluded: {len(excluded_files)}")
        print(f"Skipped directories: {len(skipped_dirs)}")
        print(f"Failed: {len(failed_files)}")

        if skipped_dirs and not recursive:
            print("\nSkipped directories (use -r flag to include):")
            for dir_path in skipped_dirs:
                FileColorPrinter.print_info(f"  {dir_path}")

        if failed_files:
            print("\nFailed files:")
            for file_path, error in failed_files:
                FileColorPrinter.print_error(f"  {file_path}: {error}")
    else:
        if skipped_dirs and not recursive:
            FileColorPrinter.print_success(
                f"Processed: {len(processed_files)} files "
                f"(directories skipped: {len(skipped_dirs)}, excluded: {len(excluded_files)}, failed: {len(failed_files)})\n"
                f"Result: {output_file}"
            )
        else:
            FileColorPrinter.print_success(
                f"Processed: {len(processed_files)} files "
                f"(skipped: {len(excluded_files)}, failed: {len(failed_files)})\n"
                f"Result: {output_file}"
            )


def main():
    parser = argparse.ArgumentParser(
        description="Combine directory files into a single markdown file",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "paths",
        nargs="*",
        default=["."],
        help="Files or directories to process",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Output file path (default: Combined-HHMM.txt in current directory)",
    )
    parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="Recursive search in subdirectories",
    )
    parser.add_argument(
        "-e", "--exclude", action="append", default=[], help="File exclusion pattern"
    )
    parser.add_argument(
        "--no-default-excludes", action="store_true", help="Disable default exclusions"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output"
    )

    args = parser.parse_args()

    try:
        combine_files(
            paths=args.paths,
            recursive=args.recursive,
            exclude_patterns=args.exclude,
            use_default_excludes=not args.no_default_excludes,
            verbose=args.verbose,
            output_path=args.output,
        )
    except KeyboardInterrupt:
        FileColorPrinter.print_error("Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        FileColorPrinter.print_error(f"Critical error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
