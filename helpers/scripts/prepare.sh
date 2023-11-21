#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
bold=`tput bold`
reset=`tput sgr0`

readarray -t files < templates

replace_symlink_with_files() {
  for file in *; do
      # Check if the target is a symlink
      if [ -L "$file" ]; then
          real_path=$(readlink -f "$file")
          rm "$file"
          cp "$real_path" "$file"
          echo "replaced: $file"
      fi
  done
}

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

if [[ "$1" == "--replace" || "$1" == "-r" ]]; then
    replace_symlink_with_files
elif [[ "$1" == "--add" || "$1" == "-a" ]]; then
    add_symlink
elif [[ "$1" == "-delete" || "$1" == "-d" ]]; then
    delete_symlink
elif [[ "$1" == "-copy" || "$1" == "-c" ]]; then
    copy_files
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 {--replace|-r|--add|-a}"
else
    echo "Usage: $0 {--replace|-r|--add|-a|--delete|-d}"
fi
