#!/bin/bash

move_files() {
    local debug=false
    local interactive=false
    local source=""
    local destination=""

    # Parse options first
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -d|--debug)
                debug=true
                shift
                ;;
            -i|--interactive)
                interactive=true
                shift
                ;;
            -h|--help)
                echo "Usage: move_files [options] [source] [destination]"
                echo "Options:"
                echo "  -d, --debug        Show debug information"
                echo "  -i, --interactive  Ask before moving each file"
                echo "  -h, --help         Show this help message"
                echo ""
                echo "Default source: $HOME/storage/shared/share"
                echo "Default destination: $HOME"
                return 0
                ;;
            *)
                if [ -z "$source" ]; then
                    source="$1"
                elif [ -z "$destination" ]; then
                    destination="$1"
                else
                    echo "Error: Unexpected argument '$1'"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Set defaults if not provided
    source="${source:-$HOME/storage/shared/share}"
    destination="${destination:-$HOME}"

    if [ ! -d "$source" ]; then
        echo "Error: Source directory '$source' does not exist"
        return 1
    fi

    if [ ! -d "$destination" ]; then
        echo "Error: Destination directory '$destination' does not exist"
        return 1
    fi

    if [ -z "$(ls -A "$source")" ]; then
        echo "Source directory is empty"
        return 0
    fi

    if $debug; then
        echo "Source: $source"
        echo "Destination: $destination"
        echo "Files to move:"
        ls -la "$source"
    fi

    if $interactive; then
        while IFS= read -r -d '' file; do
            if [ -f "$file" ]; then
                read -p "Move $(basename "$file")? [y/N] " response
                if [[ "${response}" =~ ^[Yy]$ ]]; then
                    if mv "$file" "$destination/"; then
                        echo "Moved: $(basename "$file")"
                    else
                        echo "Failed to move: $(basename "$file")"
                    fi
                fi
            elif [ -d "$file" ] && [ "$file" != "$source" ]; then
                read -p "Move directory $(basename "$file")? [y/N] " response
                if [[ "${response}" =~ ^[Yy]$ ]]; then
                    if mv "$file" "$destination/"; then
                        echo "Moved directory: $(basename "$file")"
                    else
                        echo "Failed to move directory: $(basename "$file")"
                    fi
                fi
            fi
        done < <(find "$source" -maxdepth 1 -print0)
    else
        if mv -t "$destination" "$source"/*; then
            echo "Files moved successfully"
        else
            echo "No files to move or error occurred"
        fi
    fi
}

# Execute the function with all provided arguments
move_files "$@"
