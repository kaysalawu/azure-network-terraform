
# hub1
#----------------------------------------
vnet_name = ${HUB1_VNET_NAME}
vnet_ranges = ${HUB1_VNET_RANGES}
vm_name = ${HUB1_VM_NAME}
vm_ip = ${HUB1_VM_IP}
%{~ for k,v in HUB1_SUBNETS }
${k} = ${v}
%{~ endfor }

# hub2
#----------------------------------------
vnet_name = ${HUB2_VNET_NAME}
vnet_ranges = ${HUB2_VNET_RANGES}
vm_name = ${HUB2_VM_NAME}
vm_ip = ${HUB2_VM_IP}
%{~ for k,v in HUB2_SUBNETS }
${k} = ${v}
%{~ endfor }

# Spoke1
#----------------------------------------
vnet_name = ${SPOKE1_VNET_NAME}
vnet_ranges = ${SPOKE1_VNET_RANGES}
vm_name = ${SPOKE1_VM_NAME}
vm_ip = ${SPOKE1_VM_IP}
%{~ for k,v in SPOKE1_SUBNETS }
${k} = ${v}
%{~ endfor }

# spoke2
#----------------------------------------
vnet_name = ${SPOKE2_VNET_NAME}
vnet_ranges = ${SPOKE2_VNET_RANGES}
vm_name = ${SPOKE2_VM_NAME}
vm_ip = ${SPOKE2_VM_IP}
%{~ for k,v in SPOKE2_SUBNETS }
${k} = ${v}
%{~ endfor }

# spoke3
#----------------------------------------
vnet_name = ${SPOKE3_VNET_NAME}
vnet_ranges = ${SPOKE3_VNET_RANGES}
vm_name = ${SPOKE3_VM_NAME}
vm_ip = ${SPOKE3_VM_IP}
%{~ for k,v in SPOKE3_SUBNETS }
${k} = ${v}
%{~ endfor }

# branch1
#----------------------------------------
vnet_name = ${BRANCH1_VNET_NAME}
vnet_ranges = ${BRANCH1_VNET_RANGES}
vm_name = ${BRANCH1_VM_NAME}
vm_ip = ${BRANCH1_VM_IP}
%{~ for k,v in BRANCH1_SUBNETS }
${k} = ${v}
%{~ endfor }
