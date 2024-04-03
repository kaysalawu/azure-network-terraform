#!/bin/bash

if [[ "$#" -lt 1 ]]; then
  echo "Missing argument for resource group."
  show_help
  return 1
fi
RG=$1
VNET=$(az network vnet list -g $RG --query "[].name" -o tsv)

echo "Resource group: $RG"
echo -e "VNET: $VNET\n"

get_user_choice() {
  read -p "#? " choice
  if [ -z "$choice" ]; then
    echo "No option selected. Exiting..."
    return 1
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#options[@]} ]; then
    echo "Invalid option. Exiting..."
    return 1
  fi
}

private_subnet() {
  echo "Select a Subnet:"
  # mapfile to list all subnets in the vnet
  mapfile -t subnets < <(az network vnet subnet list -g $RG --vnet-name G10-hub-vnet --query "[].name" -o tsv)
  select subnet in "${subnets[@]}"; do
    echo -e "\n[$subnet]"
    local tasks=("Enable private subnet" "Disable private subnet")
    for i in "${!tasks[@]}"; do printf "%d) %s\n" $((i+1)) "${tasks[$i]}"; done
    get_user_choice
    case $choice in
      1) if az network vnet subnet update -n $subnet -g $RG --vnet-name G10-hub-vnet --default-outbound false > /dev/null; then echo "Success!"; else echo "Failed!"; fi ;;
      2) if az network vnet subnet update -n $subnet -g $RG --vnet-name G10-hub-vnet --default-outbound true > /dev/null; then echo "Success!"; else echo "Failed!"; fi ;;
    esac
    break
  done
}

service_endpoint() {
  echo "Configuring service endpoint..."
}

add_public_IP_to_VM() {
  echo "Adding public IP to VM..."
}

add_VM_to_Load_Balancer_SNAT() {
  echo "Adding VM to Load Balancer SNAT..."
}

add_Subnet_to_NAT_Gateway() {
  echo "Adding Subnet to NAT Gateway..."
}

show_help() {
  echo "Usage: $0 [OPTION]"
  echo "Options:"
  echo "  --helper, -h   Show help."
}

if [[ "$1" == "--helper" ]] || [[ "$1" == "-h" ]]; then
  show_help
  return 0
fi

echo "What do you want to configure?"
options=(
  "Private subnet"
  # "Service endpoint"
  # "Add public IP to VM"
  # "Add VM to Load Balancer SNAT"
  # "Add Subnet to NAT Gateway"
)

for i in "${!options[@]}"; do
  printf "%d) %s\n" $((i+1)) "${options[$i]}"
done

get_user_choice

case $choice in
  1) private_subnet ;;
  # 2) service_endpoint ;;
  # 3) add_public_IP_to_VM ;;
  # 4) add_VM_to_Load_Balancer_SNAT ;;
  # 5) add_Subnet_to_NAT_Gateway ;;
esac


