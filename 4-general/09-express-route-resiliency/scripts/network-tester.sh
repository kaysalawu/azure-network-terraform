#! bin/bash

app_dir="../../../scripts/megaport/app/app/"

# fault simulation runbook

# 1. Disable BGP on Lab09-er1-pri
python3 $app_dir/main.py bgp disable --mcr salawu-lab09-mcr1 --vxc Lab09-er1-pri

