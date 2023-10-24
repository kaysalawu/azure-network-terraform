%{~ for k,v in NODES }

# ${k}
#----------------------------------------
VNET_NAME = ${v.VNET_NAME}
VNET_RANGES = ${v.VNET_RANGES}
VM_NAME = ${v.VM_NAME}
VM_IP = ${v.VM_IP}
--- Subnets ---
%{~ for x,y in v.SUBNETS }
${x} = ${y}
%{~ endfor }
--- Services ---
%{~ if try(v.APPS_URL, "") != "" }
APPS_URL = ${v.APPS_URL}
%{~ endif }
%{~ endfor }

