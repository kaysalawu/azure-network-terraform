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

terraform_docs_dirs=(
modules
)

main_dirs=(
1-hub-and-spoke
2-virtual-wan
3-network-manager
)

main_dirs_excluded=(
)

custom_dirs=(
4-general
)

function showUsage() {
  echo -e "\nUsage: $0 [options]\n\
  --diff, -f     : Run diff between local and template blueprints\n\
  --copy, -c     : Copy templates files to local\n\
  --delete, -x   : Delete local files specified in templates\n\
  --plan, -p     : Run terraform plan on all target directories\n\
  --validate, -v : Run terraform validate on all target directories\n\
  --cleanup, -u  : Delete terraform state files\n\
  --docs, -d     : Generate terraform docs\n\
  --custom-plan, -cp  : Run custom terraform plan\n\
  --custom-validate, -cv : Run custom terraform validate\n\
  --custom-cleanup, -cu : Run custom terraform cleanup"
}

is_excluded() {
    local dir_name=$(basename "$1")
    for excluded in "${main_dirs_excluded[@]}"; do
        if [[ "$dir_name" == "$excluded" ]]; then
            return 0 # True
        fi
    done
    return 1 # False
}

run_task_on_dirs() {
    local task=$1
    local prompt_option=$2
    shift 2

    if [[ $prompt_option == "--prompt" ]]; then
        read -p "Run $task on all directories? (y/n): " yn
        if [[ $yn != [Yy] ]]; then
            echo -e "Skipping $task...\n"
            return
        fi
    fi

    for dir in "${main_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo && echo -e "$dir"
            echo "----------------------------------"
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ] && ! is_excluded "$subdir"; then
                    echo -e "${subdir#*/}"
                    $task "$subdir" "$@"
                fi
            done
        fi
    done
    echo -e "\n${char_celebrate} done!"
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

run_terraform_docs() {
    read -p "Generate terraform docs? (y/n): " yn
    if [[ $yn == [Yy] ]]; then
        local original_dir=$(pwd)
        for dir in "${terraform_docs_dirs[@]}"; do
            if [ -d "$dir" ]; then
                for subdir in "$dir"/*/; do
                    if [ -d "$subdir" ] && ! is_excluded "$subdir"; then
                        cd "$subdir" || exit
                        terraform-docs markdown table . --output-file README.md --output-mode inject --show=requirements,inputs,outputs > /dev/null
                        echo -e "${char_pass} ${subdir#${original_dir}/}README.md updated!${reset}"
                        cd "$original_dir" || exit
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
}

function run_terraform_plan_custom() {
    for dir in "${custom_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo && echo "$(basename "${subdir%/}")"
                    echo "----------------------------------"
                    terraform_plan "$subdir"
                fi
            done
        fi
    done
}

function run_terraform_validate_custom() {
    for dir in "${custom_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for subdir in "$dir"/*/; do
                if [ -d "$subdir" ]; then
                    echo && echo "$(basename "${subdir%/}")"
                    echo "----------------------------------"
                    terraform_validate "$subdir"
                fi
            done
        fi
    done
}

function run_terraform_cleanup_custom() {
    read -p "Delete terraform state? (y/n): " yn
    if [[ $yn == [Yy] ]]; then
        for dir in "${custom_dirs[@]}"; do
            if [ -d "$dir" ]; then
                for subdir in "$dir"/*/; do
                    if [ -d "$subdir" ]; then
                        echo && echo "$(basename "${subdir%/}")"
                        echo "----------------------------------"
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

case "$1" in
  "--diff" | "-f")
    echo && run_task_on_dirs dir_diff --no-prompt
    ;;
  "--copy" | "-c")
    echo && run_task_on_dirs copy_files --no-prompt
    ;;
  "--delete" | "-x")
    echo && run_task_on_dirs delete_files --prompt
    ;;
  "--plan" | "-p")
    echo && run_task_on_dirs terraform_plan --no-prompt
    ;;
  "--validate" | "-v")
    echo && run_task_on_dirs terraform_validate --no-prompt
    ;;
  "--cleanup" | "-u")
    echo && run_task_on_dirs terraform_cleanup --prompt
    ;;
  "--docs" | "-d")
    echo && run_terraform_docs --prompt
    ;;
  "--custom-plan" | "-cp")
    echo && run_terraform_plan_custom
    ;;
  "--custom-validate" | "-cv")
    echo && run_terraform_validate_custom
    ;;
  "--custom-cleanup" | "-cu")
    echo && run_terraform_cleanup_custom
    ;;
  "--help" | "-h")
    showUsage
    ;;
  *)
    showUsage
    ;;
esac

cd "$working_dir" || exit
