#!/bin/bash

char_pass="\u2714"
char_fail="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"

color_green=$(tput setaf 2)
color_red=$(tput setaf 1)
reset=$(tput sgr0)

working_dir=$(pwd)
while [[ $PWD != '/' && ${PWD##*/} != 'azure-network-terraform' ]]; do cd ..; done
if [[ $PWD == '/' ]]; then
    echo "Could not find azure-network-terraform directory"
    exit 1
fi
modules_dir="$PWD/modules"

main_dirs=(
1-hub-and-spoke
2-virtual-wan
3-network-manager
)

all_dirs=(
1-hub-and-spoke
2-virtual-wan
3-network-manager
#4-general
)

function showUsage() {
  echo -e "\nUsage: $0\n\
  --diff, -f     : Run diff between local and template blueprints\n\
  --copy, -c     : Copy templates files to local\n\
  --delete, -x   : Delete local files specified in templates\n\
  --plan, -p     : Run terraform plan on all target directories\n\
  --validate, -v : Run terraform validate on all target directories\n\
  --cleanup, -u  : Delete terraform state files\n\
  --docs, -d     : Generate terraform docs"
}

dir_diff() {
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
                echo -e "  ${char_exclamation} $local_file"
                all_diffs_ok=false
            fi
        else
            echo -e "  ${char_notfound} notFound: $local_file"
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
            echo -e "  ${char_pass} cp: $file"
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
            echo -e "    ${char_fail} rm: $local_file"
        rm "$local_file"
        fi
    done
    cd "$original_dir" || exit
}

terraform_validate(){
    local original_dir=$(pwd)
    cd "$1" || exit
    terraform init > /dev/null 2>&1
    echo -e "  ${char_pass} terraform init"
    echo -e "  ${char_executing} terraform validate ..."
    if ! terraform validate; then
        echo -e "${color_red}Terraform validation failed${reset}"
        return 1
    fi
    cd "$original_dir" || exit
}

terraform_plan(){
    local original_dir=$(pwd)
    cd "$1" || exit
    terraform init > /dev/null 2>&1
    echo -e "  ${char_pass} terraform init"
    echo -e "  ${char_executing} terraform plan ..."
    if ! terraform plan > /dev/null 2>&1; then
        echo -e "${color_red}Terraform plan failed${reset}"
        return 1
    fi
    echo -e "  ${color_green}${char_pass} Success!${reset}\n"
    cd "$original_dir" || exit
}

terraform_cleanup(){
    local original_dir=$(pwd)
    cd "$1" || exit
    rm -rf .terraform 2> /dev/null
    rm .terraform.lock.hcl 2> /dev/null
    rm terraform.tfstate.backup 2> /dev/null
    rm terraform.tfstate 2> /dev/null
    echo -e "  ${color_green}${char_pass} Cleaned!${reset}"
    cd "$original_dir" || exit
}

terraform_docs(){
    local original_dir=$(pwd)
    cd "$1" || exit
    terraform-docs markdown . > README.md
    echo -e "  ${color_green}${char_pass} Success!${reset}\n"
    cd "$original_dir" || exit
}

run_dir_diff() {
    for dir in "${all_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo -e "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo -e "${subdir#*/}"
                    dir_diff "$subdir"
                fi
            done
        fi
    done
    echo -e "\n${char_celebrate} done!"
}

run_copy_files() {
    for dir in "${main_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo -e "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo -e "${subdir#*/}"
                    copy_files "$subdir"
                fi
            done
        fi
    done
    echo -e "\n${char_celebrate} done!"
}

run_delete_files() {
    read -p "Delete all template files? (y/n): " yn
    if [[ $yn == [Yy] ]]; then
        for dir in "${main_dirs[@]}"; do
            if [ -d "$dir" ]; then
                echo && echo -e "$dir"
                echo "----------------------------------"
                for subdir in "$dir"/*/; do
                    if [ -d "$subdir" ]; then
                        echo -e "${subdir#*/}"
                        delete_files "$subdir"
                    fi
                done
            fi
        done
    elif [[ $yn == [Nn] ]]; then
        return 1
    else
        echo -e "Invalid input. Please answer y or n."
        return 1
    fi
    echo -e "\n${char_celebrate} done!"
}

run_terraform_plan() {
    echo
    for dir in "${all_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo -e "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo -e "${subdir#*/}"
                    terraform_plan "$subdir"
                fi
            done
        fi
    done
    echo -e "\n${char_celebrate} done!"
}

run_terraform_validate() {
    echo
    for dir in "${all_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo -e "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo -e "${subdir#*/}"
                    terraform_validate "$subdir"
                fi
            done
        fi
    done
    echo -e "\n${char_celebrate} done!"
}

run_terraform_cleanup() {
    read -p "Delete terraform state? (y/n): " yn
    if [[ $yn == [Yy] ]]; then
        echo
        for dir in "${all_dirs[@]}"; do
            if [ -d "$dir" ]; then
                echo && echo -e "$dir"
                echo "----------------------------------"
                for subdir in "$dir"/*/; do
                    if [ -d "$subdir" ]; then
                        echo -e "${subdir#*/}"
                        terraform_cleanup "$subdir"
                    fi
                done
            fi
        done
    elif [[ $yn == [Nn] ]]; then
        return 1
    else
        echo -e "Invalid input. Please answer y or n."
        return 1
    fi
    echo -e "\n${char_celebrate} done!"
}

run_terraform_docs() {
    read -p "Generate terraform docs? (y/n): " yn
    if [[ $yn == [Yy] ]]; then
        for dir in "$modules_dir"/*; do
            if [ -d "$dir" ]; then
                terraform-docs markdown table "$dir" --output-file "$dir/README.md" --output-mode inject
            fi
        done
    elif [[ $yn == [Nn] ]]; then
        return 1
    else
        echo -e "Invalid input. Please answer y or n."
        return 1
    fi
}

if [[ "$1" == "--diff" || "$1" == "-f" ]]; then
    echo && run_dir_diff
elif [[ "$1" == "--copy" || "$1" == "-c" ]]; then
    echo && run_copy_files
elif [[ "$1" == "--df" || "$1" == "-x" ]]; then
    echo && run_delete_files
elif [[ "$1" == "--plan" || "$1" == "-p" ]]; then
    echo && run_terraform_plan
elif [[ "$1" == "--validate" || "$1" == "-v" ]]; then
    echo && run_terraform_validate
elif [[ "$1" == "--cleanup" || "$1" == "-u" ]]; then
    echo && run_terraform_cleanup
elif [[ "$1" == "--docs" || "$1" == "-d" ]]; then
    echo && run_terraform_docs
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    showUsage
else
    showUsage
fi

cd "$working_dir" || exit
