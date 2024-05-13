#! bin/bash

app_dir="../../../scripts/megaport/app/app/"

# fault simulation runbook

# 1. Disable BGP on Poc08-er1-pri
python3 $app_dir/main.py bgp disable --mcr salawu-poc08-mcr1 --vxc Poc08-er1-pri

