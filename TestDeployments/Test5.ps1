﻿[CmdletBinding()]
Param(
  [string]$storageAccountName = $(Read-Host -prompt "Specify storage account name"),
  [string]$adminUser = $(Read-Host -prompt "Specify admin user name"),
  [string]$adminPassword = $(Read-Host -prompt "Specify admin password")
  )
  
#
# Multiple VMs with multiple data disks
#
$cloudServiceName = "resize-test5"
$availabilitySet = "AS1"
$image = "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-20151120-en.us-127GB.vhd"
$location = "West US"
$vmsize = "ExtraLarge"
$storageContainer = "http://" + $storageAccountName + ".blob.core.windows.net/test5/"
$numberOfDataDisks = "3"


$vmName = "resize-vm5-1"
$osDiskURL = $storageContainer + $cloudServiceName + "-" + $vmName
$datadiskBase = $storageContainer + $cloudServiceName + "-" + $vmName + "-data-"

$vmconfig = New-AzureVMConfig -Name $vmName -InstanceSize $vmsize -ImageName $image -MediaLocation $osDiskURL -AvailabilitySetName $availabilitySet
Add-AzureProvisioningConfig -VM $vmConfig -Windows -AdminUsername $adminUser -Password $adminPassword 
for ($i=0; $i -lt $numberOfDataDisks;$i++) {
    $dataDiskURL = $datadiskBase + $i
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 200 -LUN $i -MediaLocation $dataDiskURL -DiskLabel $i -VM $vmconfig 
}
New-AzureVM -ServiceName $cloudServiceName -VMs $vmconfig -VNetName $VNet -Location $location 


$vmName = "resize-vm5-2"
$osDiskURL = $storageContainer + $cloudServiceName + "-" + $vmName
$datadiskBase = $storageContainer + $cloudServiceName + "-" + $vmName + "-data-"

$vmconfig = New-AzureVMConfig -Name $vmName -InstanceSize $vmsize -ImageName $image -MediaLocation $osDiskURL -AvailabilitySetName $availabilitySet
Add-AzureProvisioningConfig -VM $vmConfig -Windows -AdminUsername $adminUser -Password $adminPassword 
for ($i=0; $i -lt $numberOfDataDisks;$i++) {
    $dataDiskURL = $datadiskBase + $i
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 200 -LUN $i -MediaLocation $dataDiskURL -DiskLabel $i -VM $vmconfig
}
New-AzureVM -ServiceName $cloudServiceName -VMs $vmconfig