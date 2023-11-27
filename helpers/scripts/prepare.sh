#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
bold=`tput bold`
reset=`tput sgr0`

readarray -t files < templates

add_symlink(){
  for file in "${files[@]}"; do
      ln -s "$file" .
  done
}

copy_files(){
  for file in "${files[@]}"; do
    local_file=$(basename "$file")
    if [ ! -e "$local_file" ]; then
        echo "Copy: $file"
      cp "$file" .
    else
      echo "skip: $local_file"
    fi
  done
}

delete_symlink(){
  for file in *; do
    # Check if the target is a symlink
    if [ -L "$file" ]; then
        rm "$file"
        echo "deleted: $file"
    fi
done
}

delete_files(){
  run_diff
  diff_result=$?

  # If run_diff returns 1, exit
  if [ "$diff_result" -eq 1 ]; then
      echo "Differences found, aborting delete." && echo
      return
  fi

  for file in "${files[@]}"; do
    local_file=$(basename "$file")
    if [ -e "$local_file" ]; then
        rm "$local_file"
        echo "deleted: $local_file"
    else
        echo "skip: $local_file (not found)"
    fi
  done
}

run_diff() {
    echo && echo "Running diff..."
    local all_diffs_ok=true
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
    echo "done!" && echo
}

if [[ "$1" == "--add" || "$1" == "-a" ]]; then
    add_symlink
elif [[ "$1" == "--ds" || "$1" == "-d" ]]; then
    delete_symlink
elif [[ "$1" == "--copy" || "$1" == "-c" ]]; then
    copy_files
elif [[ "$1" == "--df" || "$1" == "-x" ]]; then
    delete_files
elif [[ "$1" == "--diff" || "$1" == "-f" ]]; then
    run_diff
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 {--add|-a|--delete-symlink|-d|--copy-files|-c|--delete-files|-x|--diff|-f}"
else
    echo "Usage: $0 {--add|-a|--delete-symlink|-d|--copy-files|-c|--delete-files|-x|--diff|-f}"
fi
