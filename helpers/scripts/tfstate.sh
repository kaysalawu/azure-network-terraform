#!/bin/bash

# Sync terraform state to another directory using cron job.
# This is not the best way to persist tfstate, but it saves from losing tfstate file whilst switching git branches.
# Set the root_dir and dest_dir to your desired directories.

root_dir="$HOME/AZURE/azure-network-terraform"
dest_dir="$HOME/TFSTATE/AZURE"

echo "Scanning from root_dir: $root_dir"

find "$root_dir" -type f -name "terraform.tfstate" | while read -r tfstate_file; do
    relative_path=$(dirname "${tfstate_file#$root_dir/}")
    mkdir -p "$dest_dir/$relative_path"
    cp "$tfstate_file" "$dest_dir/$relative_path/"
    echo "Copy: ${tfstate_file#$root_dir/} --> $dest_dir/$relative_path/"
done

script_path="$HOME/AZURE/azure-network-terraform/helpers/scripts/tfstate.sh"
sudo bash -c "cat <<EOF > /etc/cron.d/tfstate-backup-azure
*/5 * * * * . $script_path 2>&1 > /dev/null
EOF"
crontab /etc/cron.d/tfstate-backup-azure


