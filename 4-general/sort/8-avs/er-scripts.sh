!#/bin/bash

clear

echo -e "\nER1 Circuit Routes Summary"
echo "======================================"
az network express-route list-route-tables-summary \
-g ${RG} \
-n ${ER1_CIRCUIT} \
--path primary \
--peering-name AzurePrivatePeering \
--query value -o table --only-show-errors

echo -e "\nER1 Circuit Routes Full"
echo "======================================"
az network express-route list-route-tables \
-g ${RG} \
-n ${ER1_CIRCUIT} \
--path primary \
--peering-name AzurePrivatePeering \
--query value -o table --only-show-errors

echo -e "\nER2 Circuit Routes Summary"
echo "======================================"
az network express-route list-route-tables-summary \
-g ${RG} \
-n ${ER2_CIRCUIT} \
--path primary \
--peering-name AzurePrivatePeering \
--query value -o table --only-show-errors

echo -e "\nER2 Circuit Routes Full"
echo "======================================"
az network express-route list-route-tables \
-g ${RG} \
-n ${ER2_CIRCUIT} \
--path primary \
--peering-name AzurePrivatePeering \
--query value -o table --only-show-errors

echo -e "\nCore1 Effective Routes"
echo "======================================"
az network nic show-effective-route-table -g ${RG} -n ${NIC_CORE1} -o table --only-show-errors

echo -e "\nCore2 Effective Routes"
echo "======================================"
az network nic show-effective-route-table -g ${RG} -n ${NIC_CORE2} -o table --only-show-errors

echo -e "\nYellow Effective Routes"
echo "======================================"
az network nic show-effective-route-table -g ${RG} -n ${NIC_YELLOW} -o table --only-show-errors

echo -e "\nHub Effective Routes"
echo "======================================"
az network nic show-effective-route-table -g ${RG} -n ${NIC_YELLOW} -o table --only-show-errors

echo -e "\nOnprem Effective Routes"
echo "======================================"
az network nic show-effective-route-table -g ${RG} -n ${NIC_ONPREM} -o table --only-show-errors
