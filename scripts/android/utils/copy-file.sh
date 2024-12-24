#!/bin/bash

copy_file() {
    # No arguments provided
    if [ $# -eq 0 ]; then
        echo "Error: No arguments provided"
        copy_file --help
        return 1
    fi

    local file=""
    local preview=false
    local line_numbers=false

    # Parse options first
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -p|--preview)
                preview=true
                shift
                ;;
            -n|--line-numbers)
                line_numbers=true
                shift
                ;;
            -h|--help)
                echo "Usage: copy_file [options] <filename>"
                echo "Options:"
                echo "  -p, --preview       Show file content before copying"
                echo "  -n, --line-numbers  Show line numbers in preview"
                echo "  -h, --help          Show this help message"
                return 0
                ;;
            -*)
                echo "Error: Unknown option $1"
                copy_file --help
                return 1
                ;;
            *)
                file="$1"
                shift
                ;;
        esac
    done

    # If no file was specified after parsing options
    if [ -z "$file" ]; then
        echo "Error: No filename provided"
        copy_file --help
        return 1
    fi

    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found"
        return 1
    fi

    if $preview; then
        echo "File content preview:"
        echo "-------------------"
        if $line_numbers; then
            nl -ba "$file"
        else
            cat "$file"
        fi
        echo "-------------------"
        read -p "Copy to clipboard? [Y/n] " response
        if [[ "${response}" =~ ^[Nn]$ ]]; then
            return 0
        fi
    fi

    if cat "$file" | termux-clipboard-set; then
        echo "Content of '$file' copied to clipboard"
    else
        echo "Error: Failed to copy to clipboard"
        return 1
    fi
}

# Execute the function with all provided arguments
copy_file "$@"
