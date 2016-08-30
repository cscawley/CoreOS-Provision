location="southcentralus" #Azure DC Location of choice
resourcegroup="ampelos-cluster" #Azure Resource Group name
vnetname="ampelos-vnet" #Virtual Network Name
vnetaddr="10.1.0.0/16" #Virtual Network CIDR
subnetname="ampelos-subnet" #Subnet name
subnetaddr="10.1.0.0/24" #Subnet CIDR
availgroup="ampelos-avail-group" #Availibilty group for VMs
storageacname="ampelosstorage01" #Storage Account for the VMs
networksecgroup="ampelos-net-sec" #Network Sec Group for VMs
#Load Balancer VM name and private IP for each
lb01_name="ampelos-lb1"
lbvm_static_IP1="10.1.0.50"
vc01_name="ampelos-vc1"
vcvm_static_IP1="10.1.0.49"
lbos_image="Canonical:UbuntuServer:16.04.0-LTS:16.04.201604203" #Ubuntu image to use `azure vm image list southcentralus canonical ubuntuserver` `azure vm image list`
lbvm_size="Standard_A0" #VM Sizes can be listed by using `azure vm sizes --location YourAzureDCLocaitonOfChoice`
azure config mode arm
#azure network public-ip create --resource-group $resourcegroup --location $location --name "$lb01_name"-pub-ip
##Virtual Nics with private IPs for load balance VMs
#azure network nic create --resource-group $resourcegroup --subnet-vnet-name $vnetname --subnet-name $subnetname #--location $location --name "$lb01_name"-priv-nic --private-ip-address $lbvm_static_IP1 --network-security-group-name #$networksecgroup --public-ip-name "$lb01_name"-pub-ip
#VM
#Create an ubuntu server to install HAProxy
azure vm create --ssh-publickey-file=ampelos-01.pub --admin-username core --name $lb01_name --vm-size $lbvm_size --resource-group $resourcegroup --vnet-subnet-name $subnetname --os-type linux --availset-name $availgroup --location $location --image-urn $lbos_image --nic-names "$lb01_name"-priv-nic --storage-account-name $storageacname
#Create an ubuntu server to install the VCS/Registry
#azure vm create --ssh-publickey-file=ampelos-01.pub --admin-username core --name $vc01_name --vm-size $lbvm_size --resource-group $resourcegroup --vnet-subnet-name $subnetname --os-type linux --availset-name $availgroup --location $location --image-urn $lbos_image --nic-names "$vc01_name"-priv-nic --storage-account-name $storageacname