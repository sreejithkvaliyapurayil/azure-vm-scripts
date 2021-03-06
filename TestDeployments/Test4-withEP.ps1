﻿#
# Note: VNet must be created before running this script
#

[CmdletBinding()]
Param(
  [string]$storageAccountName = $(Read-Host -prompt "Specify storage account name"),
  [string]$adminUser = $(Read-Host -prompt "Specify admin user name"),
  [string]$adminPassword = $(Read-Host -prompt "Specify admin password")
  )
  
#
# Multiple VMs in AS with ILB 
#
$cloudServiceName = "resize-test4ep"
$availabilitySet = "AS1"
$VNet = "resize-VNet4"
$subnet = "subnet-1"
$image = "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-20151120-en.us-127GB.vhd"
$location = "West US"
$vmsize = "Small"
$storageContainer = "http://" + $storageAccountName + ".blob.core.windows.net/test4ep/"


$ilbName = "myILBep"
$ilbConfig = New-AzureInternalLoadBalancerConfig -InternalLoadBalancerName $ilbName -SubnetName $subnet 
$lbSetName = "myLBSet"

$vmName = "resize-vm4ep-1"
$osDiskURL = $storageContainer + $cloudServiceName + "-" + $vmName

$vmconfig = New-AzureVMConfig -Name $vmName -InstanceSize $vmsize -ImageName $image -MediaLocation $osDiskURL -AvailabilitySetName $availabilitySet 
Add-AzureProvisioningConfig -VM $vmConfig -Windows -AdminUsername $adminUser -Password $adminPassword 
Set-AzureSubnet -SubnetNames $subnet -VM $vmconfig
Add-AzureEndpoint -LBSetName $lbSetName -Name "testEP" -Protocol "TCP" -LocalPort 80 -PublicPort 80 -DefaultProbe -InternalLoadBalancerName $ilbName -VM $vmconfig              
New-AzureVM -ServiceName $cloudServiceName -VMs $vmconfig -VNetName $VNet -Location $location -InternalLoadBalancerConfig $ilbConfig


$vmName = "resize-vm4ep-2"
$osDiskURL = $storageContainer + $cloudServiceName + "-" + $vmName

$vmconfig = New-AzureVMConfig -Name $vmName -InstanceSize $vmsize -ImageName $image -MediaLocation $osDiskURL -AvailabilitySetName $availabilitySet
Add-AzureProvisioningConfig -VM $vmConfig -Windows -AdminUsername $adminUser -Password $adminPassword 
Set-AzureSubnet -SubnetNames $subnet -VM $vmconfig
Add-AzureEndpoint -LBSetName $lbSetName -Name "testEP" -Protocol "TCP" -LocalPort 80 -PublicPort 80 -DefaultProbe -InternalLoadBalancerName $ilbName -VM $vmconfig
New-AzureVM -ServiceName $cloudServiceName -VMs $vmconfig 