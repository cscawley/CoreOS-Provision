#infrastructure var
location="southcentralus" #Azure DC Location of choice
resourcegroup="ampelos-cluster" #Azure Resource Group name
vnetname="ampelos-vnet" #Virtual Network Name
vnetaddr="10.1.0.0/16" #Virtual Network CIDR
subnetname="ampelos-subnet" #Subnet name
subnetaddr="10.1.0.0/24" #Subnet CIDR
availgroup="ampelos-avail-group" #Availibilty group for VMs
storageacname="ampelosstorage01" #Storage Account for the VMs
networksecgroup="ampelos-net-sec" #Network Sec Group for VMs
#server var
name="CIWorker1"
static_IP1="10.1.0.60"
image="Canonical:UbuntuServer:16.04.0-LTS:16.04.201604203" #Ubuntu image to use `azure vm image list southcentralus canonical ubuntuserver` `azure vm image list`
size="Standard_A1" #VM Sizes can be listed by using `azure vm sizes --location YourAzureDCLocaitonOfChoice`

#execute
azure config mode arm

#Create public IP
azure network public-ip create --resource-group $resourcegroup --location $location --name "$name"-pub-ip

#Virtual Nics with private IPs
azure network nic create --resource-group $resourcegroup --subnet-vnet-name $vnetname --subnet-name $subnetname --location $location --name "$name"-priv-nic --private-ip-address $static_IP1 --network-security-group-name $networksecgroup --public-ip-name "$name"-pub-ip

#Create an ubuntu server
azure vm create --ssh-publickey-file=ampelos-01.pub --admin-username core --name $name --vm-size $size --resource-group $resourcegroup --vnet-subnet-name $subnetname --os-type linux --availset-name $availgroup --location $location --image-urn $image --nic-names "$name"-priv-nic --storage-account-name $storageacname