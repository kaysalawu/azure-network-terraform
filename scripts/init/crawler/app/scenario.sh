#!/bin/bash

private_subnet() {
  echo "Configuring private subnet..."
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
options=("Private subnet" "Service endpoint" "Add public IP to VM" "Add VM to Load Balancer SNAT" "Add Subnet to NAT Gateway")

select opt in "${options[@]}"
do
  case $opt in
    "Private subnet")
      private_subnet
      break
      ;;
    "Service endpoint")
      service_endpoint
      break
      ;;
    "Add public IP to VM")
      add_public_IP_to_VM
      break
      ;;
    "Add VM to Load Balancer SNAT")
      add_VM_to_Load_Balancer_SNAT
      break
      ;;
    "Add Subnet to NAT Gateway")
      add_Subnet_to_NAT_Gateway
      break
      ;;
    *) echo "Invalid option $REPLY";;
  esac
done
