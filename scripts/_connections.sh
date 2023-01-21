rg=BXRG

#for vhubname in `az network vhub list -g $rg --query "[].id" -o tsv | rev | cut -d'/' -f1 | rev`
for vhubname in `az network vhub list -g $rg --query "[].id" -o tsv | rev | cut -d'/' -f1 | rev`
do
  for connection in `az network vhub connection list -g $rg --vhub-name $vhubname --query "[].id" -o tsv`
   do
     echo "****************************************"
     echo -e vHUB: $vhubname 
     echo -e Connection: $(echo $connection | rev | cut -d'/' -f1 | rev)
     echo "****************************************"
     az network vhub connection list -g $rg --vhub-name $vhubname \
     --query "[].routingConfiguration"
     #--output table
     echo
   done
done

