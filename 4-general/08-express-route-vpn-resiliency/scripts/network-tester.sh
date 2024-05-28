#! bin/bash

app_dir="../../../scripts/megaport/app/app/"

# fault simulation runbook

# 1. Disable BGP on Lab08-er1-pri
python3 $app_dir/main.py bgp disable --mcr salawu-lab08-mcr1 --vxc Lab08-er1-pri

