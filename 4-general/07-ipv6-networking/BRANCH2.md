
Contents
- [Branch2 Tests](#branch2-tests)
- [Access to Azure over ExpressRoute](#access-to-azure-over-expressroute)
- [1. Ping IP](#1-ping-ip)
- [2. Ping DNS](#2-ping-dns)
- [3. Curl DNS](#3-curl-dns)
- [4. Private Link Service](#4-private-link-service)
- [5. Private Link Access to Storage Account](#5-private-link-access-to-storage-account)
- [6. Private Link Access to Storage Account from On-premises](#6-private-link-access-to-storage-account-from-on-premises)
- [7. Effective Routes](#7-effective-routes)
  - [8.](#8)


## Branch2 Tests

The following tests are performed on Branch2 to verify reachability over ExpressRoute to Azure resources.

## Access to Azure over ExpressRoute

Login to on-premises virtual machine `Lab07-branch2Vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

Run the following tests from inside the serial console session.

## 1. Ping IP

This script pings the IP addresses of some test virtual machines and reports reachability and round trip time.

**1.1.** Run the IP ping test

```sh
ping-ipv4
ping-ipv6
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch2Vm:~$ ping-ipv4

 ping ipv4 ...

branch2  - 10.10.0.5 -NA
branch2  - 10.20.0.5 -OK 0.053 ms
hub1-vm  - 10.11.0.5 -OK 5.701 ms
spoke1   - 10.1.0.5 -OK 5.559 ms
spoke2   - 10.2.0.5 -OK 5.313 ms
internet - icanhazip.com -NA
```

```sh
azureuser@branch2Vm:~$ ping-ipv6

 ping ipv6 ...

branch2  - fd00:db8:10::5 -NA
branch2  - fd00:db8:20::5 -OK 0.041 ms
hub1-vm  - fd00:db8:11::5 -OK 4.286 ms
spoke1   - fd00:db8:1::5 -OK 6.385 ms
spoke2   - fd00:db8:2::5 -OK 4.750 ms
internet - icanhazip.com -OK 1.745 ms
```

</details>
<p>

## 2. Ping DNS

This script pings the DNS name of some test virtual machines and reports reachability and round trip time. This tests hybrid DNS resolution between on-premises and Azure.

**2.1.** Run the DNS ping test

```sh
ping-dns4
ping-dns6
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch2Vm:~$ ping-dns4

 ping dns ipv4 ...

branch2vm.corp - 10.10.0.5 -NA
branch2vm.corp - 10.20.0.5 -OK 0.042 ms
hub1vm.eu.az.corp - 10.11.0.5 -OK 5.102 ms
spoke1vm.eu.az.corp - 10.1.0.5 -OK 5.899 ms
spoke2vm.eu.az.corp - 10.2.0.5 -OK 4.610 ms
icanhazip.com - 104.16.184.241 -NA
```

```sh
azureuser@branch2Vm:~$ ping-dns6

 ping dns ipv6 ...

branch2vm.corp - fd00:db8:10::5 -NA
branch2vm.corp - fd00:db8:20::5 -OK 0.033 ms
hub1vm.eu.az.corp - fd00:db8:11::5 -OK 5.171 ms
spoke1vm.eu.az.corp - fd00:db8:1::5 -OK 5.398 ms
spoke2vm.eu.az.corp - fd00:db8:2::5 -OK 4.909 ms
icanhazip.com - 2606:4700::6810:b9f1 -OK 2.052 ms
```

</details>
<p>

## 3. Curl DNS

This script uses curl to check reachability of web server (python Flask) on the test virtual machines. It reports HTTP response message, round trip time and IP address.

**3.1.** Run the DNS curl test

```sh
curl-dns4
curl-dns6
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch2Vm:~$ curl-dns4

 curl dns ipv4 ...

 - branch2vm.corp
200 (0.003380s) - 10.20.0.5 - branch2vm.corp
200 (0.021734s) - 10.11.0.5 - hub1vm.eu.az.corp
200 (0.013847s) - 10.11.7.88 - spoke3pls.eu.az.corp
200 (0.010773s) - 10.1.0.5 - spoke1vm.eu.az.corp
200 (0.012362s) - 10.2.0.5 - spoke2vm.eu.az.corp
200 (0.020949s) - 104.16.184.241 - icanhazip.com
200 (0.036891s) - 10.11.7.99 - https://lab07spoke3sa5466.blob.core.windows.net/spoke3/spoke3.txt
```

```sh
azureuser@branch2Vm:~$ curl-dns6

 curl dns ipv6 ...

 - branch2vm.corp
200 (0.005057s) - fd00:db8:20::5 - branch2vm.corp
200 (0.020939s) - fd00:db8:11::5 - hub1vm.eu.az.corp
000 (0.016459s) -  - spoke3pls.eu.az.corp
200 (0.023080s) - fd00:db8:1::5 - spoke1vm.eu.az.corp
200 (0.023074s) - fd00:db8:2::5 - spoke2vm.eu.az.corp
200 (0.074481s) - 2606:4700::6810:b9f1 - icanhazip.com
000 (0.002315s) -  - https://lab07spoke3sa5466.blob.core.windows.net/spoke3/spoke3.txt
```

</details>
<p>

## 4. Private Link Service

**4.1.** Test access to ***spoke3*** web application using the private endpoint in ***hub1***.

```sh
curl spoke3pls.eu.az.corp
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch2Vm:~$ curl -4 spoke3pls.eu.az.corp
{
  "app": "SERVER",
  "hostname": "spoke3Vm",
  "server-ipv4": "10.3.0.5",
  "server-ipv6": "fd00:db8:3::5",
  "remote-addr": "10.3.6.4",
  "headers": {
    "host": "spoke3pls.eu.az.corp",
    "user-agent": "curl/7.68.0",
    "accept": "*/*"
  }
}
```

</details>
<p>

The `Hostname` and `server-ipv4` fields identify the target web server - in this case ***spoke3*** virtual machine. The `remote-addr` field (as seen by the web server) is an IP address in the Private Link Service NAT subnet in ***spoke3***.

## 5. Private Link Access to Storage Account

A storage account with a container blob deployed and accessible via private endpoints in ***hub1***. The storage accounts have the following naming convention:

* lab07spoke3sa\<AAAA\>.blob.core.windows.net

Where ***\<AAAA\>*** is a randomly generated two-byte string.

**5.1.** On your Cloudshell (or local machine), get the storage account hostname and blob URL.

```sh
spoke3_storage_account=$(az storage account list -g Lab07_HubSpoke_Nva_1Region_RG --query "[?contains(name, 'lab07spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n" && echo
```

<details>

<summary>Sample output</summary>

```sh
lab07spoke3sa4104.blob.core.windows.net
```

</details>
<p>

**5.2.** Resolve the hostname

```sh
nslookup $spoke3_sgtacct_host
```

<details>

<summary>Sample output</summary>

```sh
3-hub-spoke-nva-single-region$ nslookup $spoke3_sgtacct_host
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
lab07spoke3sa4104.blob.core.windows.net  canonical name = lab07spoke3sa4104.privatelink.blob.core.windows.net.
lab07spoke3sa4104.privatelink.blob.core.windows.net      canonical name = blob.db3prdstr19a.store.core.windows.net.
Name:   blob.db3prdstr19a.store.core.windows.net
Address: 20.150.75.36
```

</details>
<p>

We can see that the endpoint is a public IP address, ***20.150.75.36***. We can see the CNAME `lab07spoke3sa4104.privatelink.blob.core.windows.net.` created for the storage account which recursively resolves to the public IP address.

**5.3.** Test access to the storage account blob.

```sh
curl $spoke3_blob_url && echo
```

<details>

<summary>Sample output</summary>

```sh
Hello, World!
```

</details>
<p>

## 6. Private Link Access to Storage Account from On-premises

**6.1** Login to on-premises virtual machine `Lab07-branch2Vm` via the [serial console](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/serial-console-overview#access-serial-console-for-virtual-machines-via-azure-portal):
  - username = ***azureuser***
  - password = ***Password123***

 We will test access from `Lab07-branch2Vm` to the storage account for ***spoke3*** via the private endpoint in ***hub1***.

**6.2.** Run `az login` to authenticate to Azure.

```sh
az login
```

<details>

<summary>Sample output</summary>

```json
azureuser@branch2Vm:~$ az login --identity
[
  {
    "environmentName": "AzureCloud",
    "homeTenantId": "aaa-bbb-ccc-ddd-eee",
    "id": "xxx-yyy-1234-1234-1234",
    "isDefault": true,
    "managedByTenants": [
      {
        "tenantId": "your-tenant-id"
      }
    ],
    "name": "some-random-name",
    "state": "Enabled",
    "tenantId": "your-tenant-id",
    "user": {
      "assignedIdentityInfo": "MSI",
      "name": "systemAssignedIdentity",
      "type": "servicePrincipal"
    }
  }
]
```

</details>
<p>

**6.3.** Get the storage account hostname and blob URL.

```sh
spoke3_storage_account=$(az storage account list -g Lab07_HubSpoke_Nva_1Region_RG --query "[?contains(name, 'lab07spoke3sa')].name" -o tsv)

spoke3_sgtacct_host="$spoke3_storage_account.blob.core.windows.net"
spoke3_blob_url="https://$spoke3_sgtacct_host/spoke3/spoke3.txt"

echo -e "\n$spoke3_sgtacct_host\n" && echo
```

<details>

<summary>Sample output</summary>

```sh
lab07spoke3sa4104.blob.core.windows.net
```

</details>
<p>

**6.4.** Resolve the storage account DNS name

```sh
nslookup $spoke3_sgtacct_host
```

<details>

<summary>Sample output</summary>

```sh
azureuser@branch2Vm:~$ nslookup $spoke3_sgtacct_host
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
lab07spoke3sa4104.blob.core.windows.net  canonical name = lab07spoke3sa4104.privatelink.blob.core.windows.net.
Name:   lab07spoke3sa4104.privatelink.blob.core.windows.net
Address: 10.11.7.99
```

</details>
<p>

We can see that the storage account hostname resolves to the private endpoint ***10.11.7.99*** in ***hub1***. The following is a summary of the DNS resolution from `Lab07-branch2Vm`:

- On-premises server `Lab07-branch2Vm` makes a DNS request for `lab07spoke3sa4104.blob.core.windows.net`
- The request is received by on-premises DNS server `Lab07-branch2-dns`
- The DNS server resolves `lab07spoke3sa4104.blob.core.windows.net` to the CNAME `lab07spoke3sa4104.privatelink.blob.core.windows.net`
- The DNS server has a conditional DNS forwarding defined in the branch2 unbound DNS configuration file, [output/branch2Dns.sh](./output/branch2Dns.sh).

  ```sh
  forward-zone:
          name: "privatelink.blob.core.windows.net."
          forward-addr: 10.11.8.4
  ```

  DNS Requests matching `privatelink.blob.core.windows.net` will be forwarded to the private DNS resolver inbound endpoint in ***hub1*** (10.11.8.4).
- The DNS server forwards the DNS request to the private DNS resolver inbound endpoint in ***hub1*** - which returns the IP address of the storage account private endpoint in ***hub1*** (10.11.7.99)

**6.5.** Test access to the storage account blob.

```sh
curl $spoke3_blob_url && echo
```

<details>

<summary>Sample output</summary>

```sh
Hello, World!
```

</details>
<p>

## 7. Effective Routes

**7.1.** Run the following command and select `Lab07-branch2-vm-main-nic` when prompted.

```sh
bash ../../scripts/_routes_nic.sh Lab07_HubSpoke_Nva_1Region_RG
```

<details>

<summary>Sample output</summary>

```sh
Effective routes for Lab07-branch2-vm-main-nic

Source                 Prefix                 State    NextHopType            NextHopIP
---------------------  ---------------------  -------  ---------------------  ------------
Default                10.20.0.0/20           Active   VnetLocal
Default                10.20.16.0/20          Active   VnetLocal
VirtualNetworkGateway  10.1.0.0/20            Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.1.0.0/20            Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  10.2.0.0/20            Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.2.0.0/20            Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  10.11.0.0/20           Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.11.0.0/20           Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  10.11.16.0/20          Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.11.16.0/20          Active   VirtualNetworkGateway  10.20.88.111
Default                0.0.0.0/0              Active   Internet
Default                fd00:db8:20::/56       Active   VnetLocal
Default                fd00:db8:20:aa00::/56  Active   VnetLocal
VirtualNetworkGateway  fd00:db8:1::/56        Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  fd00:db8:1::/56        Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  fd00:db8:2::/56        Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  fd00:db8:2::/56        Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  fd00:db8:11::/56       Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  fd00:db8:11::/56       Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  fd00:db8:11:aa00::/56  Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  fd00:db8:11:aa00::/56  Active   VirtualNetworkGateway  10.20.88.111
Default                ::/0                   Active   Internet
```

</details>
<p>


**7.2.** Run the following command and select `Lab07-hub1-nva-untrust-nic` when prompted.

```sh
bash ../../scripts/_routes_nic.sh Lab07_HubSpoke_Nva_1Region_RG
```

<details>

<summary>Sample output</summary>

```sh
Effective routes for Lab07-hub1-nva-untrust-nic

Source                 Prefix                 State    NextHopType            NextHopIP
---------------------  ---------------------  -------  ---------------------  ------------
Default                10.11.0.0/20           Active   VnetLocal
Default                10.11.16.0/20          Active   VnetLocal
Default                10.1.0.0/20            Active   VNetPeering
Default                10.2.0.0/20            Active   VNetPeering
VirtualNetworkGateway  10.10.0.0/24           Active   VirtualNetworkGateway  10.11.16.14
VirtualNetworkGateway  10.10.0.0/24           Active   VirtualNetworkGateway  10.11.16.15
VirtualNetworkGateway  10.20.0.0/20           Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.20.0.0/20           Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  10.20.16.0/20          Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  10.20.16.0/20          Active   VirtualNetworkGateway  10.20.88.111
Default                0.0.0.0/0              Active   Internet
Default                10.11.7.99/32          Active   InterfaceEndpoint
Default                10.11.7.88/32          Active   InterfaceEndpoint
Default                fd00:db8:11::/56       Active   VnetLocal
Default                fd00:db8:11:aa00::/56  Active   VnetLocal
Default                fd00:db8:1::/56        Active   VNetPeering
Default                fd00:db8:2::/56        Active   VNetPeering
VirtualNetworkGateway  fd00:db8:20:aa00::/56  Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  fd00:db8:20:aa00::/56  Active   VirtualNetworkGateway  10.20.88.111
VirtualNetworkGateway  fd00:db8:20::/56       Active   VirtualNetworkGateway  10.20.88.110
VirtualNetworkGateway  fd00:db8:20::/56       Active   VirtualNetworkGateway  10.20.88.111
Default                ::/0                   Active   Internet
```

</details>
<p>

**7.3.** Run the following command and select the number for `Lab07-spoke1-vm-main-nic` when prompted.

```sh
bash ../../scripts/_routes_nic.sh Lab07_HubSpoke_Nva_1Region_RG
```

<details>

<summary>Sample output</summary>

```sh
Effective routes for Lab07-spoke1-vm-main-nic

Source    Prefix                 State    NextHopType        NextHopIP
--------  ---------------------  -------  -----------------  -----------------
Default   10.1.0.0/20            Active   VnetLocal
Default   10.11.16.0/20          Active   VNetPeering
Default   10.11.0.0/20           Invalid  VNetPeering
Default   0.0.0.0/0              Invalid  Internet
User      0.0.0.0/0              Active   VirtualAppliance   10.11.2.99
User      10.11.0.0/20           Active   VirtualAppliance   10.11.2.99
Default   10.11.7.99/32          Active   InterfaceEndpoint
Default   10.11.7.88/32          Active   InterfaceEndpoint
Default   fd00:db8:1::/56        Active   VnetLocal
Default   fd00:db8:11:aa00::/56  Active   VNetPeering
Default   fd00:db8:11::/56       Invalid  VNetPeering
Default   ::/0                   Invalid  Internet
User      fd00:db8:11::/56       Active   VirtualAppliance   fd00:db8:11:2::99
User      ::/0                   Active   VirtualAppliance   fd00:db8:11:2::99
```

</details>
<p>

### 8.

