#!/bin/bash

# Define the function to import the Terraform resource
function import_ars() {
  # Extract variables from the error message
  resource_id="/subscriptions/ec265026-bc67-44f6-92bc-9849685d921d/resourceGroups/HubSpokeS2RG/providers/Microsoft.Network/virtualHubs/HubSpokeS2-hub2-vnet0-ars"

  subscription_id=$(echo "$resource_id" | cut -d'/' -f3)
  resource_group_name=$(echo "$resource_id" | cut -d'/' -f5)
  virtual_hub_name=$(echo "$resource_id" | cut -d'/' -f8 | cut -d'-' -f1-3)
  vnet_name=$(echo "$resource_id" | cut -d'/' -f8 | cut -d'-' -f4)
  ars_name=$(echo "$resource_id" | cut -d'/' -f9)

  # Use the variables to import the Terraform resource
  terraform import module.hub2.azurerm_route_server.ars["0"] "$resource_id"
}

# Prompt the user for input
echo "Please select an option:"
echo "1. Import ARS"
echo "2. Quit"

read option

# Run the function based on the user's selection
case "$option" in
  1)
    import_ars
    ;;
  2)
    exit
    ;;
  *)
    echo "Invalid option. Please try again."
    ;;
esac
