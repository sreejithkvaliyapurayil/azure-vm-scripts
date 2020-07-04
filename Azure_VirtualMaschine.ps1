# ------------------------------------------------------------------------------
# PowerShell Script
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Functions:
#
#   vm_show($name)
#   vm_stop($name)
#   vm_start($name)
#   vm_show_list()
#
#   vm_getservicename($name)
#
#   vm_showsnapshots($virtualMachineName)
#
#   vm_export($virtualMachineName, [string]$exportFile)
#   vm_import(...)
#
#   vm_backup(...)
#   vm_restore(...)
#
#   vm_copy2othersubscripton(...)
#
#   vm_set_static_ip(...)
#
# ------------------------------------------------------------------------------
# TODO: 
# * not null check
# * empty check
#
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# check, if object empty or null
# ------------------------------------------------------------------------------
Function obj_EmptyOrNull($obj, [int]$debug=0) {
  $result = $true

  if ($obj -eq $null) {
    $result = $false
  }
  
  if ($obj -eq "") {
    $result = $false
  }
  
  if ($debug -eq 1) { Write-Host "rc: $result" }
  return $result
}
# test:
# cls
# Write-Host ""
# $rc = obj_EmptyOrNull ""
# $rc = obj_EmptyOrNull "ok"
# $rc = obj_EmptyOrNull
# $o = "abdC"
# $rc = obj_EmptyOrNull $o
# if (!(obj_EmptyOrNull)) { Write-Host "error" }
# if (!(obj_EmptyOrNull "")) { Write-Host "error" }
# if (!(obj_EmptyOrNull "a")) { Write-Host "error" }
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# show vm infos
# ------------------------------------------------------------------------------
Function vm_show([string]$name)
{
  Write-Host ""
  Write-Host "Informations about the vm '$name'"
  
  # get vm by name (only one result!)
  $o = (Get-AzureVM | Get-AzureVM -Name $name) | Select -First 1
  if (!(obj_EmptyOrNull $o)) {
    Write-Host "vm '$name' not found"
    return
  } 
  # $o
  
  # get service & state by name
  $svcname = $o.ServiceName
  $state = $o.PowerState
  Write-Host "[vm: '$name', service: '$svcname', state: '$state']"
  # $o
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# stop a vm
# ------------------------------------------------------------------------------
Function vm_stop([string]$name)
{
  Write-Host ""
  # get vm by name
  # $o = Get-AzureVM | Get-AzureVM -Name $name
  # get vm by name (only one result!)
  $o = (Get-AzureVM | Get-AzureVM -Name $name) | Select -First 1
  
  # if ($o -eq $null) {
  if (!(obj_EmptyOrNull $o)) {
    Write-Host "vm '$name' not found"
    return
  }  

  # get service & state by name
  $svcname = $o.ServiceName
  $state = $o.PowerState

  Write-Host "[vm: $name, service: $svcname, state: $state]"
  # stop only if started
  if ($state -eq "Started") {
    Write-Host "stop vm $name"
    Stop-AzureVM -ServiceName $svcname -Name $name -Verbose -Force
  } else {
    Write-Host "vm $name is not or not yet running"
  }
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# start a vm
# ------------------------------------------------------------------------------
Function vm_start($name)
{
  Write-Host ""
  # get vm by name
  # get vm by name (only one result!)
  $o = (Get-AzureVM | Get-AzureVM -Name $name) | Select -First 1

  if ($o -eq $null) {
    Write-Host "vm '$name' not found"
    return
  } 

  # get service & state by name
  $svcname = $o.ServiceName
  $state = $o.PowerState

  Write-Host "[vm: $name, service: $svcname, state: $state]"
  # start only if stopped
  if ($state -eq "Stopped") {
    Write-Host "start vm $name"
    Start-AzureVM -ServiceName $svcname -Name $name -Verbose
  } else {
    Write-Host "vm $name is already running"
  }
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# get name of cloud serive from vm
# ------------------------------------------------------------------------------
Function vm_getservicename($name)
{
  # Write-Host ""
  # get vm by name
  # get vm by name (only one result!)
  $o = (Get-AzureVM | Get-AzureVM -Name $name) | Select -First 1

  if ($o -eq $null) {
    Write-Host "vm '$name' not found"
    return
  }  

  # get service & state by name
  $svcname = $o.ServiceName
  if ($svcname -eq $null) {
    return "?"
  } else {
    return $svcname
  }
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# show snapshots for vm
# ------------------------------------------------------------------------------
Function vm_showsnapshots($virtualMachineName)
{
  Write-Host ""
  # get vm by name
  $o = Get-AzureVM | Get-AzureVM -Name $virtualMachineName
  if ($o -eq $null) {
    Write-Host "vm '$name' not found"
    return
  }  

  # get service & state by name
  $cloudServiceName = $o.ServiceName

  # min date = heute -1
  [DateTime]$minimumDate = [DateTime]::UtcNow.AddDays($maximumDays * -1)

  # Write the header to the console
  Write-Host "========================================================================="
  Write-Host "VHD Snapshots for $virtualMachineName in $cloudServiceName cloud service."
  Write-Host "========================================================================="
  $virtualMachine = Get-AzureVM -ServiceName $cloudServiceName -Name $virtualMachineName

  # if the virtual machine was retrieved successfully continue
  if($virtualMachine -ne $null)
  {
    # Write the operating system disk header.
    Write-Host ""
    Write-Host "Operating System Disk Snapshots."
    Write-Host "-------------------------------------------------------------------------"
    Write-Host ""
    
    # Get the snapshots for the virtual machines operating system disk
    $osDisk = $virtualMachine | Get-AzureOSDisk 
    $existingSnapshots = Get-BlobSnapshots $osDisk.MediaLink

    # Write the details of the operating system so the user can identify the specific blob.
    Write-Host "Disk Name: $($osDisk.DiskName)"
    Write-Host "VHD: $($osDisk.MediaLink)"

    # Iterate through each of the snapshots and write out the date.
    $cnt1 = 0
    foreach($snapshot in $existingSnapshots)
    {
      $cnt1++
      #if($snapshot.SnapshotTime -ge $minimumDate)
      #{
        Write-Host "$($snapshot.SnapshotTime)"
      #}
    }
    if ($cnt1 -eq 0) { Write-Host "no snapshots found!" }

    # Write the data disk section header.
    Write-Host ""
    Write-Host "Data Disk Snapshots."
    Write-Host "-------------------------------------------------------------------------"

    $dataDisks = $virtualMachine | Get-AzureDataDisk

    # Iterate through the data disks
    $cnt2 = 0
    foreach($dataDisk in $dataDisks)
    {      
      # Write the header fo the specific data disk
      Write-Host ""
      Write-Host "Disk Name: $($dataDisk.DiskName)"
      Write-Host "VHD: $($dataDisk.MediaLink)"
      
      $existingDataDiskSnapshots = Get-BlobSnapshots $dataDisk.MediaLink.AbsoluteUri        
      
      foreach($snapshot in $existingDataDiskSnapshots)
      {
        $cnt2++
        # If the data disk snapshots were retrieved successfully write the dates out
        # if($snapshot.SnapshotTime -ge $minimumDate)
        #{
          Write-Host "$($snapshot.SnapshotTime)"
        #}
      }
    } 
    if ($cnt2 -eq 0) { Write-Host "no snapshots found!" }

    # Write the completion footer.
    Write-Host ""
    Write-Host "Done."
    Write-Host "-------------------------------------------------------------------------"
  }
  else
  {
    # An error happened retrieving the virtual machine so let the user know
    Write-Host "The virtual machine could not be retrieved."
    Write-Host "-------------------------------------------------------------------------"
  }
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# export vm
#
# vm_export "SalesDemo" "d:\dev\home\HEAD\powershell\msazure\SalesDemo.xml"
# ------------------------------------------------------------------------------
Function vm_export([string]$virtualMachineName, [string]$exportFile)
{
  Write-Host ""
  # get vm by name
  # $o = Get-AzureVM | Get-AzureVM -Name $virtualMachineName
  $o = (Get-AzureVM | Get-AzureVM -Name $virtualMachineName) | Select -First 1
  if ($o -eq $null) {
    Write-Host "vm '$name' not found"
    return
  }  

  # get service & state by name
  $cloudServiceName = $o.ServiceName
  
  Write-Host "export virtual maschine $virtualMachineName on service $cloudServiceName"    
  Write-Host "-------------------------------------------------------------------------"
  
  $rc = Export-AzureVM -ServiceName $cloudServiceName -Name $virtualMachineName -Path $exportFile
  Write-Host "rc:"
  $rc
  
  Write-Host ""
  Write-Host "-------------------------------------------------------------------------"
  
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# import vm
# ------------------------------------------------------------------------------
Function vm_import([string]$virtualMachineName, [string]$exportFile, [string]$virtualLAN)
{
  Write-Host ""
  # get vm by name
  # $o = Get-AzureVM | Get-AzureVM -Name $virtualMachineName
  $o = (Get-AzureVM | Get-AzureVM -Name $virtualMachineName) | Select -First 1
  if ($o -eq $null) {
    Write-Host "vm '$name' not found"
    return
  }  
  
  If (!(Test-Path $exportFile)) { 
      Write-Host "Error: file '$exportFile' not found!"
      return
  }
  
  # TODO: virtualLAN
  

  # get service & state by name
  $cloudServiceName = $o.ServiceName
  
  Write-Host "import virtual maschine $virtualMachineName on service $cloudServiceName"    
  Write-Host "-------------------------------------------------------------------------"
  
  $rc = Import-AzureVM -Path $exportFile | New-AzureVM -ServiceName $vm.ServiceName -VNetName $virtualLAN
  Write-Host "rc:"
  $rc
  
  Write-Host ""
  Write-Host "-------------------------------------------------------------------------"
  
}

# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# backup a vm
# ------------------------------------------------------------------------------
Function vm_backup([string]$virtualMachineName, [string]$exportPath)
{
  # see
  # http://blogs.technet.com/b/heyscriptingguy/archive/2014/01/24/create-backups-of-virtual-machines-in-windows-azure-by-using-powershell.aspx
  
  Write-Host ""
  Write-Host "Start backup for vm '$virtualMachineName'" -foreground "Magenta"
  Write-Host ""
  
  if ( $exportPath -eq $null) { 
    Write-Host "Error: exportPath empty"
    return
  }

  # get vm by name
  # $o = Get-AzureVM | Get-AzureVM -Name $virtualMachineName
  # get vm by name (only one result!)
  $o = (Get-AzureVM | Get-AzureVM -Name $virtualMachineName) | Select -First 1
  
  if ($o -eq $null) {
    Write-Host "vm '$virtualMachineName' not found"
    return
  }   

  # get service & state by name
  $cloudServiceName = $o.ServiceName

  # 1.
  Write-Host "1: get vm"
  # Write-Host "---"
  $vm = Get-AzureVM -ServiceName $cloudServiceName -Name $virtualMachineName
  if ($vm -eq $null) {
    Write-Host "vm '$virtualMachineName' not found"
    return
  }
  
  # 2.   
  Write-Host "2: stopp vm, if running"
  # Write-Host "---"
  $state = $o.PowerState
  if ($state -eq "Started") {
    Write-Host "please wait..."
    $vm | Stop-AzureVM -StayProvisioned    
  }
  Write-Host ""
  
  # 3.
  Write-Host "3: get os disk"
  # Write-Host "---"
  $vmOSDisks = $vm | Get-AzureOSDisk
  if ($vmOSDisks -eq $null) {
    Write-Host "os disc not found"
    return
  }
  Write-Host $vmOSDisks.Name
  
  # 4.
  Write-Host "4: get data disk(s)"
  $vmDataDisks = $vm | Get-AzureDataDisk
  if ($vmDataDisks -ne $null) {
    Write-Host "---"  
    $vmDataDisks
  }

  # 5. 
  Write-Host "5: get storage account name, set subscription"
  Write-Host "---"    
  $StorageAccountName = $vmOSDisks.MediaLink.Host.Split('.')[0]
  Write-Host "StorageAccountName: $StorageAccountName"  
  Get-AzureSubscription | Set-AzureSubscription -CurrentStorageAccount $StorageAccountName
  
  # 6.
  Write-Host "6. create backup container, if needed"    
  Write-Host "---"    
  $backupContainerName = "backups"
  if (!(Get-AzureStorageContainer -Name $backupContainerName -ErrorAction SilentlyContinue)) {  
    New-AzureStorageContainer -Name $backupContainerName -Permission Off
    Write-Host "container '$backupContainerName' created in storage '$StorageAccountName'."
  }
      
  # 7. backup os disc (Force = override)
  Write-Host "---"    
  $vmOSBlobName = $vmOSDisks.MediaLink.Segments[-1]
  $vmOSBlobName   
  $vmOSContainerName = $vmOSDisks.MediaLink.Segments[-2].Split('/')[0]
  $vmOSContainerName
  
  Write-Host "copy os disc"    
  $cnt_os = 0
  ForEach ( $vmOsDisk in $vmOSDisk ) {
    Write-Host "vmOSContainerName: $vmOSContainerName"
    Start-AzureStorageBlobCopy -SrcContainer $vmOSContainerName -SrcBlob $vmOSBlobName -DestContainer $backupContainerName -Force 
    Get-AzureStorageBlobCopyState -Container $backupContainerName -Blob $vmOSBlobName -WaitForComplete
    $cnt_os++
  }

  # 8. backup data disc (Force = override)
  Write-Host "copy data disc(s)" 
  $cnt_data = 0
  ForEach ( $vmDataDisk in $vmDataDisks ) {
    $vmDataBlobName = $vmDataDisk.MediaLink.Segments[-1]
    $vmDataContainerName = $vmDataDisk.MediaLink.Segments[-2].Split('/')[0]
    Write-Host "vmDataContainerName: $vmDataContainerName"        
    Start-AzureStorageBlobCopy -SrcContainer $vmDataContainerName -SrcBlob $vmDataBlobName -DestContainer $backupContainerName -Force
    Get-AzureStorageBlobCopyState -Container $backupContainerName -Blob $vmDataBlobName -WaitForComplete
    $cnt_data++
  }
  
#  Write-Host "x. show the backups"
#  Write-Host "----------------------------"
#  # Get-AzureStorageBlob -Container $backupContainerName 
#  $backups = Get-AzureStorageBlob -Container $backupContainerName
#  obj_EmptyOrNull $backups
#  $cnt_backup = 0
#  Write-Host "----------------------------"
#  ForEach ( $backup in $backups ) {
#    $vhdname = $backup.Name
#    Write-Host "disc : $vhdname"
#    $cnt_backup++
#  }
    
  # TODO: es werden derzeit alle backups gezählt!!!    
#  Write-Host ""
#  Write-Host "os discs      : $cnt_os"
#  Write-Host "data discs    : $cnt_data"
#  Write-Host "backup discs  : $cnt_backup "
#  $cnt_sum = $cnt_data + $cnt_os
#  if ( $cnt_sum -eq $cnt_backup ) {
#    Write-Host "backuped $cnt_backup of $cnt_sum discs. => seems to be ok!"
#  } else {
#    Write-Host "backuped $cnt_backup of $cnt_sum discs. => Error!!!"
#    # return -1
#  }  
  
  # ----------------------------------------------------------
  # check backup container
  # ----------------------------------------------------------
  Write-Host ""
  Write-Host "show the backuped vhds in the container '$backupContainerName'"
  Write-Host "--------------------------------------------------------------"
  $backups = Get-AzureStorageBlob -Container $backupContainerName
  $backups
  if ($backups -eq $null) { Write-Host "Error: container not found" }
  $cnt_vhd = 0
  $cnt_vhd_all = 0
  ForEach ( $backup in $backups ) {
    $vhdname = $backup.Name
    $vhdsize = $backup.TotalBytes / 1000 / 1000
    $cnt_vhd_all++
    if ($vhdname.Contains($vm_name)) {
      Write-Host "disc : '$vhdname' is part of the vm '$vm_name' (size $vhdsize MB)." -foreground "Green"
      $cnt_vhd++
    } else {
      Write-Host "disc : '$vhdname' is part of other vm!" -foreground "Yellow"
    }    
  }
  
  Write-Host "--------------------------------------------------------"
  Write-Host "Number of OS discs                          : $cnt_os"
  Write-Host "Number of Data discs                        : $cnt_data"  
  Write-Host "Number of saved vhds for the given vm       : $cnt_vhd "
  Write-Host "Number of all saved vhds                    : $cnt_vhd_all "
  $cnt_sum = $cnt_data + $cnt_os
  if ( $cnt_sum -eq $cnt_sum ) {
    Write-Host "Backuped $cnt_vhd of $cnt_sum discs. => seems to be ok!" -foreground "Green"
  } else {
    Write-Host "Backuped $cnt_vhd of $cnt_sum discs. => Error: Some vhds are missing!!!" -foreground "Red"
  }  
  Write-Host ""
  # ----------------------------------------------------------  
  
  
  Write-Host "x. export vm definition"
  Write-Host "----------------------------"  
  # PATH?
  
  # start vm
  Write-Host "x: start vm"
  vm_start $virtualMachineName
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# restore a existing vm from backupped vhds
# ------------------------------------------------------------------------------
Function vm_restore([string]$virtualMachineName, [string]$exportPath)
{
  # see
  # http://blogs.technet.com/b/keithmayer/archive/2014/02/04/step-by-step-perform-cloud-restores-of-windows-azure-virtual-machines-using-powershell-part-2.aspx
  
  Write-Host ""
  Write-Host "start restore of $virtualMachineName..."
  Write-Host ""
  
  if ( $exportPath -eq $null) { # ???
    Write-Host "Error: exportPath empty"
    return
  }  
  
  if (!(Test-Path -path $exportPath)) {
    Write-Host "path '$exportPath' not found!!"
  }
  
  
  # get vm by name
  $o = Get-AzureVM | Get-AzureVM -Name $virtualMachineName
  if ($o -eq $null) {
    Write-Host "vm '$name' not found"
    return
  }  
  $o

  # get service & state by name
  $cloudServiceName = $o.ServiceName

  # 1.
  Write-Host "1: get vm"
  Write-Host "---"
  $vm = Get-AzureVM -ServiceName $cloudServiceName -Name $virtualMachineName

  # 2.   
  Write-Host "2: stop vm, if needed"
  Write-Host "---"
  $state = $o.PowerState
  if ($state -eq "Started") {
    $vm | Stop-AzureVM -StayProvisioned
  }
  
  Write-Host "get os disc"
  $vmOSDisk = $vm | Get-AzureOSDisk
  
  Write-Host "get data disc(s)"
  $vmDataDisks = $vm | Get-AzureDataDisk
  
  Write-Host "export vm definition to xml in '$exportPath'"
  # $exportFolder = "d:\dev\home\HEAD\powershell\msazure"
  
  if (!(Test-Path -Path $exportPath)) {
    New-Item -Path $exportPath -ItemType Directory
  }
  
  # convention: path\subscription_name + vm_name . xml
  $exportFile = $exportPath + "\" + $vm.Name + ".xml"
  $vm | Export-AzureVM -Path $exportFile
  Write-Host "---"
  
  Write-Host "remove vm"
  Remove-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name
  
  $backupContainerName = "backups"
  
  
  
  Write-Host "---"
  Write-Host "add os disc from backup"  
  $vmOSDiskName = $vmOSDisk.DiskName  
  $vmOSDiskuris = $vmOSDisk.MediaLink    
  $vmOSBlobName = $vmOSDiskuris.Segments[-1]  
  $vmOSOrigContainerName = $vmOSDiskuris.Segments[-2].Split('/')[0]   
  $StorageAccountName = $vmOSDiskuris.Host.Split('.')[0] 
  
  While ( (Get-AzureDisk -DiskName $vmOSDiskName).AttachedTo ) { Start-Sleep 5 }
  Remove-AzureDisk -DiskName $vmOSDiskName -DeleteVHD
  Start-AzureStorageBlobCopy -SrcContainer $backupContainerName -SrcBlob $vmOSBlobName -DestContainer $vmOSOrigContainerName -Force  
  Get-AzureStorageBlobCopyState -Container $vmOSOrigContainerName -Blob $vmOSBlobName -WaitForComplete 
  Add-AzureDisk -DiskName $vmOSDiskName -MediaLocation $vmOSDiskuris.AbsoluteUri -OS Windows
  
  Write-Host "---"
  Write-Host "add data disc from backup"
  ForEach ( $vmDataDisk in $vmDataDisks ) 
  {  
    Write-Host "vmDataDisk: $vmDataDisk"
    $vmDataDiskName = $vmDataDisk.DiskName
    $vmDataDiskuris = $vmDataDisk.MediaLink
    $vmDataBlobName = $vmDataDiskuris.Segments[-1]
    $vmDataOrigContainerName = $vmDataDiskuris.Segments[-2].Split('/')[0]
    
    # go
    While ( (Get-AzureDisk -DiskName $vmDataDiskName).AttachedTo ) { Start-Sleep 5 }
    Remove-AzureDisk -DiskName $vmDataDiskName -DeleteVHD
    Start-AzureStorageBlobCopy -SrcContainer $backupContainerName -SrcBlob $vmDataBlobName -DestContainer $vmDataOrigContainerName -Force
    Get-AzureStorageBlobCopyState -Container $vmDataOrigContainerName -Blob $vmDataBlobName -WaitForComplete
    Add-AzureDisk -DiskName $vmDataDiskName -MediaLocation $vmDataDiskuris.AbsoluteUri  
  }
  
  # import vm definition...
  Write-Host "import vm from xml definition"
  Write-Host "---"
  # TODO: woher kommt der VNetName ??
  Import-AzureVM -Path $exportFile | New-AzureVM -ServiceName $vm.ServiceName -VNetName "TBLAN"
  
  # manuell, falls es einen abbruch gibt...
  # $exportFile = "d:\dev\home\HEAD\powershell\msazure\TBWS2012R2.xml"
  # $cloudServiceName = "TBWS2012R2"
  # Import-AzureVM -Path $exportFile | New-AzureVM -ServiceName $cloudServiceName -VNetName "TBLAN"

  # TODO: starte vm? -- geht automatisch?
  
  Write-Host "end"
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# x
# ------------------------------------------------------------------------------
Function vm_copy2othersubscripton([string]$virtualMachineName)
{
  Write-Host ""
  Write-Host "copy xxxx for vm '$virtualMachineName'" -foreground "Magenta"
  Write-Host ""
  
#  if ( $exportPath -eq $null) { 
#    Write-Host "Error: exportPath empty"
#    return
#  }

  # get vm by name (only one result!)
  $o = (Get-AzureVM | Get-AzureVM -Name $virtualMachineName) | Select -First 1
  
  if ($o -eq $null) {
    Write-Host "vm '$virtualMachineName' not found"
    return
  }   

  # get service & state by name
  $cloudServiceName = $o.ServiceName

  # 1.
  # Write-Host "1: get vm"
  # Write-Host "---"
  # $vm = Get-AzureVM -ServiceName $cloudServiceName -Name $virtualMachineName
  # if ($vm -eq $null) {
  #  Write-Host "vm '$virtualMachineName' not found"
  #  return
  #}

  
  # Get a collection of all disks.
  # $azureDisks = Get-AzureDisk
  
  # $vm | Get-AzureOSDisk
  
  
  
  $srcContext = ""
  $blobUri = ""
  
  $destContext = ""
  $DestContainerName = ""
  $blob.Name = ""
  
  # Schedule a blob copy operation to the destination account.
  $destCopyState = Start-AzureStorageBlobCopy -Context $srcContext -SrcUri $blobUri `
    -DestContext $destContext -DestContainer $DestContainerName `
    -DestBlob $blob.Name -Force
  $destCopyStates += $destCopyState
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Static IP for VM
# ------------------------------------------------------------------------------
Function vm_set_static_ip([string]$virtualMachineName, [string]$newIP, [string]$vnetName)
{
  Write-Host ""
  Write-Host "set static ip for vm '$virtualMachineName'" -foreground "Magenta"
  Write-Host ""
  
  
  # get vm by name (only one result!)
  $o = (Get-AzureVM | Get-AzureVM -Name $virtualMachineName) | Select -First 1
  if (!(obj_EmptyOrNull $o)) {
    Write-Host "vm '$name' not found"
    return
  } 
       
  Write-Host "show actual ip"
  $o | Select-Object Name,IpAddress,DNSName,InstanceSize,PowerState,ServiceName
         
  
  Write-Host "test if the wanted ip $newIP is free."
  Test-AzureStaticVNetIP -VNetName $vnetName -IPAddress $newIP
  if ($LastExitCode -ne 0) 
  {
    Write-Host "ip is free"
    Write-Host "set ip to $wanted_ip"
    Get-AzureVM -ServiceName $o.ServiceName -Name $virtualMachineName | Set-AzureStaticVNetIP -IPAddress $newIP | Update-AzureVM    
    Write-Host ${"rc: " + $LastExitCode}
  } else {
    Write-Host "ip not free"
  }

  Write-Host "show new ip"
  $p = (Get-AzureVM | Get-AzureVM -Name $virtualMachineName) | Select -First 1
  $p | Select-Object Name,IpAddress,DNSName,InstanceSize,PowerState,ServiceName

  Write-Host "test the new ip"
  ipconfig /flushdns
  ping $newIP
  
  
  Write-Host "end"
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Show List of VMs
# ------------------------------------------------------------------------------
Function vm_show_list()
{
  Write-Host ""
  Write-Host "show list of virtual maschines in the subscriptions" -foreground "Magenta"
  Write-Host ""
  
  $o = Get-AzureVM
  if (!(obj_EmptyOrNull $o)) {
    Write-Host "no vm found"
    return
  }
  ## $o | Select Name,ServiceName, VM, Status, IpAddress | Format-Table
  $o | Get-AzureVM | Select Name,ServiceName, PowerState, IpAddress,InstanceSize | Format-Table
  
  # $o | Format-Table
  # Get-AzureVM | Format-List
  # Get-AzureVM | Get-AzureVM | Format-List Name, IpAddress, DNSName, InstanceSize, PowerState
  
  # DeploymentName
  # Name
  # Label
  # VM
  # InstanceStatus
  # IpAddress
  # InstanceStateDetails
  # PowerState
  # InstanceErrorCode
  # InstanceFaultDomain
  # InstanceName
  # InstanceUpgradeDomain
  # InstanceSize
  # AvailabilitySetName
  # DNSName
  # ServiceName
  # OperationDescription
  # OperationId
  # OperationStatus  
  
  #Write-Host ""
  #ForEach ( $vm in $o ) {
  #  $obj = (Get-AzureVM | Get-AzureVM -Name $vm.Name) | Select -First 1
  #  $obj | Select Name,ServiceName, PowerState, IpAddress,InstanceSize | Format-Table
  #}
  
    
  Write-Host ""
}
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# end
# ------------------------------------------------------------------------------
