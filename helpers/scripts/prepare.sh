#!/bin/bash

char_pass="\u2714"
char_fail="\u274c"
char_question="\u2753"
char_notfound="\u26D4"
char_exclamation="\u2757"
char_celebrate="\u2B50"
char_executing="\u23F3"

color_green=$(tput setaf 2)
reset=$(tput sgr0)

dir_diff() {
    local all_diffs_ok=true
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

    if [ "$all_diffs_ok" = false ]; then
        return 1
    fi
    echo -e "  ${color_green}${char_pass} Success!${reset}\n"
}

copy_files(){
    readarray -t files < templates
    for file in "${files[@]}"; do
        local_file=$(basename "$file")
        if [ ! -e "$local_file" ]; then
            echo -e "  ${char_pass} cp: $file"
        cp "$file" .
        fi
    done
}

delete_files(){
    read -p "Delete all template files? (y/n): " yn
    if [[ $yn == [Yy] ]]; then
        readarray -t files < templates
        for file in "${files[@]}"; do
            local_file=$(basename "$file")
            if [ -e "$local_file" ]; then
                echo -e "    ${char_fail} rm: $local_file"
            rm "$local_file"
            fi
        done
    fi
}

terraform_validate(){
    terraform init > /dev/null 2>&1
    echo -e "  ${char_pass} terraform init"
    echo -e "  ${char_executing} terraform validate ..."
    if ! terraform validate; then
        echo -e "Terraform validation failed"
        return 1
    fi
}

terraform_plan(){
    terraform init > /dev/null 2>&1
    echo -e "  ${char_pass} terraform init"
    echo -e "  ${char_executing} terraform plan ..."
    if ! terraform plan > /dev/null 2>&1; then
        echo -e "Terraform plan failed"
        return 1
    fi
    echo -e "  ${color_green}${char_pass} Success!${reset}\n"
}

terraform_cleanup(){
    read -p "Delete terraform state? (y/n): " yn
    if [[ $yn == [Yy] ]]; then
        rm -rf .terraform 2> /dev/null
        rm .terraform.lock.hcl 2> /dev/null
        rm terraform.tfstate.backup 2> /dev/null
        rm terraform.tfstate 2> /dev/null
        echo -e "  ${color_green}${char_pass} Cleaned!${reset}"
    fi
}

if [[ "$1" == "--diff" || "$1" == "-f" ]]; then
    clear && dir_diff
elif [[ "$1" == "--copy" || "$1" == "-c" ]]; then
    clear && copy_files
elif [[ "$1" == "--df" || "$1" == "-x" ]]; then
    clear && delete_files
elif [[ "$1" == "--plan" || "$1" == "-p" ]]; then
    clear && terraform_plan
elif [[ "$1" == "--validate" || "$1" == "-v" ]]; then
    clear && terraform_validate
elif [[ "$1" == "--cleanup" || "$1" == "-u" ]]; then
    clear && terraform_cleanup
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "Usage: $0 {--diff|-f | --copy|-c | --delete-files|-x | --plan|-p | --validate|-v | --cleanup|-u}"
else
    echo -e "Usage: $0 {--diff|-f | --copy|-c | --delete-files|-x | --plan|-p | --validate|-v | --cleanup|-u}"
fi

