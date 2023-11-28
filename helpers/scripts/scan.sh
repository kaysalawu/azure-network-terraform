#!/bin/bash

dirs=(
1-hub-and-spoke
2-virtual-wan
3-network-manager
)

run_diff() {
    local all_diffs_ok=true
    echo "..."
    for file in "${files[@]}"; do
        local_file=$(basename "$file")
        if [ -e "$local_file" ]; then
            diff "$local_file" "$file" > /dev/null 2>&1
            diff_exit_status=$?

            if [ "$diff_exit_status" -ne 0 ]; then
                echo "diff: $diff_exit_status --> $local_file"
                all_diffs_ok=false
            fi
        else
            echo "notFound: $local_file"
        fi
    done

    if [ "$all_diffs_ok" = false ]; then
        return 1
    fi
    echo
}

run_dir_diff() {
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo && echo "* ${subdir#*/}"
                    run_diff "$subdir"
                fi
            done
        fi
    done
}

if [[ "$1" == "--" || "$1" == "-a" ]]; then
    add_symlink

clear
run_dir_diff
