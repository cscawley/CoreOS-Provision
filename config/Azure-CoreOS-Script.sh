#!/bin/bash
#Tested on MacOS X 10.11.3 and Ubuntu 15.10 with Azure CLI tools installed
#https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/
#Use `azure login` to get a token against your Azure subscription before running script
#--------------------------------------------------------------------------------------------
#Variables to change
location="southcentralus" #Azure DC Location of choice
resourcegroup="ampelos-cluster" #Azure Resource Group name
vnetname="ampelos-vnet" #Virtual Network Name
vnetaddr="10.1.0.0/16" #Virtual Network CIDR
subnetname="ampelos-subnet" #Subnet name
subnetaddr="10.1.0.0/24" #Subnet CIDR
availgroup="ampelos-avail-group" #Availibilty group for VMs
storageacname="ampelosstorage01" #Storage Account for the VMs
networksecgroup="ampelos-net-sec" #Network Sec Group for VMs
#VM name and private IP for each
vm01_name="ampelos-01"
vm_static_IP1="10.1.0.51"
vm02_name="ampelos-02"
vm_static_IP2="10.1.0.52"
vm03_name="ampelos-03"
vm_static_IP3="10.1.0.53"
coreos_image="coreos:coreos:Stable:835.9.0" #CoreOS image to use
vm_size="Standard_A0" #VM Sizes can be listed by using `azure vm sizes --location YourAzureDCLocaitonOfChoice`
#---------------------------------------------------------------------------------------------
#Azure CLI------------------------------------------------------------------------------------
#Azure Resource Group setup
azure config mode arm
azure group create --location $location $resourcegroup
#Azure Storage account setup
azure storage account create --location $location --resource-group $resourcegroup --type lrs $storageacname
#Azure Network Security Group setup
azure network nsg create --resource-group $resourcegroup --location $location --name $networksecgroup
#Virtual network and subnet setup
azure network vnet create --location $location --address-prefixes $vnetaddr --resource-group $resourcegroup --name $vnetname
azure network vnet subnet create --address-prefix $subnetaddr --resource-group $resourcegroup --vnet-name $vnetname --name $subnetname --network-security-group-name $networksecgroup
#Public IP for VMs (can create SSH inbound rules to access these if required)
azure network public-ip create --resource-group $resourcegroup --location $location --name "$vm01_name"-pub-ip
azure network public-ip create --resource-group $resourcegroup --location $location --name "$vm02_name"-pub-ip
azure network public-ip create --resource-group $resourcegroup --location $location --name "$vm03_name"-pub-ip
#Virtual Nics with private IPs for CoreOS VMs
azure network nic create --resource-group $resourcegroup --subnet-vnet-name $vnetname --subnet-name $subnetname --location $location --name "$vm01_name"-priv-nic --private-ip-address $vm_static_IP1 --network-security-group-name $networksecgroup --public-ip-name "$vm01_name"-pub-ip
azure network nic create --resource-group $resourcegroup --subnet-vnet-name $vnetname --subnet-name $subnetname --location $location --name "$vm02_name"-priv-nic --private-ip-address $vm_static_IP2 --network-security-group-name $networksecgroup --public-ip-name "$vm02_name"-pub-ip
azure network nic create --resource-group $resourcegroup --subnet-vnet-name $vnetname --subnet-name $subnetname --location $location --name "$vm03_name"-priv-nic --private-ip-address $vm_static_IP3 --network-security-group-name $networksecgroup --public-ip-name "$vm03_name"-pub-ip
#Create 3 CoreOS-Stable VMs, fly in cloud-config file, also provide ssh public key to connect with in future
azure vm create --custom-data=ampelos-01-cloud-config.yaml --ssh-publickey-file=ampelos-01.pub --admin-username core --name $vm01_name --vm-size $vm_size --resource-group $resourcegroup --vnet-subnet-name $subnetname --os-type linux --availset-name $availgroup --location $location --image-urn $coreos_image --nic-names "$vm01_name"-priv-nic --storage-account-name $storageacname
azure vm create --custom-data=ampelos-02-cloud-config.yaml --ssh-publickey-file=ampelos-01.pub --admin-username core --name $vm02_name --vm-size $vm_size --resource-group $resourcegroup --vnet-subnet-name $subnetname --os-type linux --availset-name $availgroup --location $location --image-urn $coreos_image --nic-names "$vm02_name"-priv-nic --storage-account-name $storageacname
azure vm create --custom-data=ampelos-03-cloud-config.yaml --ssh-publickey-file=ampelos-01.pub --admin-username core --name $vm03_name --vm-size $vm_size --resource-group $resourcegroup --vnet-subnet-name $subnetname --os-type linux --availset-name $availgroup --location $location --image-urn $coreos_image --nic-names "$vm03_name"-priv-nic --storage-account-name $storageacname
#Azure CLI------------------------------------------------------------------------------------
