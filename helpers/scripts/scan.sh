#!/bin/bash

dirs=(
1-hub-and-spoke
2-virtual-wan
3-network-manager
)

run_diff() {
    local all_diffs_ok=true
    local original_dir=$(pwd)
    cd "$1" || exit
    readarray -t files < templates
    for file in "${files[@]}"; do
        local_file=$(basename "$file")
        if [ -e "$local_file" ]; then
            diff "$local_file" "$file" > /dev/null 2>&1
            diff_exit_status=$?

            if [ "$diff_exit_status" -ne 0 ]; then
                echo "  * $local_file"
                all_diffs_ok=false
            fi
        else
            echo "  * notFound: $local_file"
        fi
    done
    cd "$original_dir" || exit

    if [ "$all_diffs_ok" = false ]; then
        return 1
    fi
}

copy_files(){
    local original_dir=$(pwd)
    cd "$1" || exit
    readarray -t files < templates
    for file in "${files[@]}"; do
        local_file=$(basename "$file")
        if [ ! -e "$local_file" ]; then
            echo "  * cp: $file"
        cp "$file" .
        fi
    done
    cd "$original_dir" || exit
}

delete_files(){
    local original_dir=$(pwd)
    cd "$1" || exit
    readarray -t files < templates
    for file in "${files[@]}"; do
        local_file=$(basename "$file")
        if [ -e "$local_file" ]; then
            echo "  * rm: $local_file"
        rm "$local_file"
        fi
    done
    cd "$original_dir" || exit
}

terraform_test(){
    local original_dir=$(pwd)
    cd "$1" || exit
    echo "  * terraform init ..."
    terraform init > /dev/null 2>&1
    echo "  * terraform validate ..."
    terraform validate
    cd "$original_dir" || exit
}

terraform_cleanup(){
    local original_dir=$(pwd)
    cd "$1" || exit
    echo "  * terraform clean ..."
    rm -rf .terraform
    rm .terraform.lock.hcl
    rm terraform.tfstate.backup
    cd "$original_dir" || exit
}

run_dir_diff() {
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo "${subdir#*/}"
                    run_diff "$subdir"
                fi
            done
        fi
    done
}

run_copy_files() {
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo "${subdir#*/}"
                    copy_files "$subdir"
                fi
            done
        fi
    done
}

run_delete_files() {
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo "${subdir#*/}"
                    delete_files "$subdir"
                fi
            done
        fi
    done
}

run_terraform_test() {
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo "${subdir#*/}"
                    terraform_test "$subdir"
                fi
            done
        fi
    done
}

run_terraform_cleanup() {
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo "${subdir#*/}"
                    terraform_cleanup "$subdir"
                fi
            done
        fi
    done
}

if [[ "$1" == "--diff" || "$1" == "-f" ]]; then
    clear && run_dir_diff
elif [[ "$1" == "--copy" || "$1" == "-c" ]]; then
    clear && run_copy_files
elif [[ "$1" == "--df" || "$1" == "-x" ]]; then
    clear && run_delete_files
elif [[ "$1" == "--test" || "$1" == "-t" ]]; then
    clear && run_terraform_test
elif [[ "$1" == "--cleanup" || "$1" == "-u" ]]; then
    clear && run_terraform_cleanup
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 {--diff|-f|--copy|-c|--delete-files|-x|--test|-t|--cleanup|-u}"
else
    echo "Usage: $0 {--diff|-f|--copy|-c|--delete-files|-x|--test|-t|--cleanup|-u}"
fi
