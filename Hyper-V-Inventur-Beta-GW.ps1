$Hostname=$env:computername
$Hostname

$hostOS = Get-WMIObject Win32_Operatingsystem -ComputerName $Hostname
Write-Host 'Hostname: ' $hostOS.Caption
Write-Host 'installiert am: ' (([WMI]'').ConvertToDateTime($hostOS.InstallDate))
$VMHOSTInfo=Get-VMHost
#Write-Host 'CPUs: ' $VMHOSTInfo.LogicalProcessorCount ' logische Kerne'
$RAM=[math]::round(($VMHOSTInfo.MemoryCapacity/1024/1024/1024))
Write-Host 'RAM: '  $RAM ' GB'

$hostHW = Get-WmiObject Win32_ComputerSystem -ComputerName $HostName
$hostEnclosure = Get-WmiObject Win32_SystemEnclosure -ComputerName $Hostname 
Write-Host 'Modell: ' ($hostHW.GetPropertyValue('Model'))
Write-Host 'Hersteller: ' ($hostHW.GetPropertyValue('Manufacturer'))
Write-Host 'Serial-Nr: ' ($hostEnclosure.GetPropertyValue('SerialNumber'))

$vProcessors = (Get-WmiObject Win32_Processor -ComputerName $HostName | Sort-Object DeviceID)
Write-Host 'CPUs: '
foreach ($CPU in $vProcessors)
{
  Write-Host ([string]$CPU.DeviceID) ($CPU.Name)
}

$vLogicalCPUs = $($vProcessors|measure-object NumberOfLogicalProcessors -sum).Sum
$vCores = $($vProcessors|measure-object NumberOfCores -sum).Sum
Write-Host 'Gesamt Kerne: ' $vCores

Write-Host 'Festplatten:'
$HostDrives=get-disk
foreach ($hostDrive in $hostDrives)
{
    Write-Host ($hostDrive.FriendlyName) ' Größe: ' ('{0:N2}' -f($hostDrive.Size / 1GB) + ' GB')    
}
Write-Host ''

$hostVolumes = (Get-Volume | Sort-Object DriveLetter,FileSystemLabel)
foreach ($hostVolume in $hostVolumes)
{
    Write-Host 'Volume' ($hostVolume.DriveLetter + ' (' + $hostVolume.FileSystemLabel + ')')
    # map volume to drive and partition
    $Parts = Get-Partition | Where-Object { $_.AccessPaths -eq $hostVolume.Path} 
		foreach ($part in $Parts)
		{
		  Write-Host 'Located on' ('Disk ' + [string]$part.DiskNumber + ', Partition ' + [string]$part.PartitionNumber)
		}
    Write-Host 'File System' ($hostVolume.FileSystem)
    # get block size
    $VolName = $hostVolume.ObjectID -replace '\\', '\\'
    $wql = "SELECT Blocksize FROM Win32_Volume WHERE DeviceID='$VolName'"
    $BlockSize = (Get-WmiObject -Query $wql -ComputerName $Hostname).Blocksize
    Write-Host 'Disk cluster size'  ('{0:N2}' -f($BlockSize / 1KB) + ' KB')
    Write-Host 'Size' ('{0:N2}' -f($hostVolume.Size / 1GB) + ' GB')
    Write-Host 'Free space' ('{0:N2}' -f($hostVolume.SizeRemaining / 1GB) + ' GB')
    write-Host ' '
}


#$hostNetworks = (Get-NetAdapter | Sort-Object Name)

$vms=Get-VM
foreach ($vm in $vms) {
    Write-Host '--------------------------------'
    Write-Host $vm.name 
    Write-host $vm.AutomaticStartAction 
    write-Host $vm.AutomaticStopAction
    $hds=$vm.HardDrives
    write-Host 'Platten:'
    foreach ($hd in $hds) {
        write-host $hd.ControllerType $hd.ControllerLocation $hd.ControllerNumber $hd.Path
        $vmHDDVHD = $hd.Path | Get-VHD -ComputerName $Hostname -ErrorAction SilentlyContinue
        if ($vmHDDVHD -ne $null) {
            Write-Host 'VHD Format: ' ($vmHDDVHD.VhdFormat)
            Write-Host 'VHD Typ: ' ($vmHDDVHD.VhdType)
            Write-Host 'Kapazität: ' ('{0:N2}' -f($vmHDDVHD.Size / 1GB) + ' GB')
        } else {
            Write-HOst 'Fehler beim Zugriff auf die Platte'  
        }

    }

}