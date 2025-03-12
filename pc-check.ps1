##
## PC check powershell script
## author: vignemail1@gmail.com
## version : 1.0 (2025-03-12)
##

# Create the output directory if it does not exist
$logDir = "C:\PCCheck"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir
}

# Create the subdirectory for event logs
$eventLogsDir = Join-Path $logDir "eventlogs"
if (!(Test-Path $eventLogsDir)) {
    New-Item -ItemType Directory -Path $eventLogsDir
}

# General log file
$generalLog = Join-Path $logDir "GeneralLog.txt"
if (!(Test-Path $generalLog)) {
    New-Item -ItemType File -Path $generalLog
} else {
    Get-Content $generalLog | Out-Null # Clear the file if it exists
}

# Function to write errors to the general log file
function Write-ErrorLog {
    param ($message)
    Add-Content -Path $generalLog -Value "$(Get-Date) - ERROR: $message"
}

# Protected folders to exclude
$protectedFolders = @(
    "C:\Windows\System32\WebThreatDefSvc",
    "C:\Windows\CSC",
    "C:\Windows\System32\LogFiles\WMI\RtBackup",
    "C:\Windows\SoftwareDistribution\Download"
)

# Function to sanitize file names
function Sanitize-FileName {
    param ($filename)
    $forbiddenCharacters = '[<>:"/\\|?*]'
    $sanitized = $filename -replace $forbiddenCharacters, '_'
    return $sanitized
}

# 1. Collect information on running processes
Write-Host "Collecting information on running processes..."
$processLog = Join-Path $logDir "Processes.txt"
if (!(Test-Path $processLog)) {
    New-Item -ItemType File -Path $processLog
}

try {
    $processes = Get-Process
    foreach ($process in $processes) {
        $processInfo = [PSCustomObject]@{
            Name        = $process.ProcessName
            Id          = $process.Id
            Path        = $process.Path
            StartTime   = $process.StartTime
            WorkingSet  = $process.WorkingSet64
            CPU         = $process.CPU
        }
        
        # Get launch arguments using WMI
        $wmiProcess = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)"
        if ($wmiProcess) {
            $processInfo.Arguments = $wmiProcess.CommandLine
        }
        
        $processInfo | Format-List | Out-String | Add-Content -Path $processLog
    }
    Add-Content -Path $generalLog -Value "$(Get-Date) - Running processes collected in $processLog"
} catch {
    Write-ErrorLog "Error collecting processes: $($Error[0].Message)"
}

# 2. Collect information on system files (.exe, .dll, .ps1, .bat)
Write-Host "`nCollecting information on system files..."
$systemFilesLog = Join-Path $logDir "SystemFiles.txt"
if (!(Test-Path $systemFilesLog)) {
    New-Item -ItemType File -Path $systemFilesLog
}

try {
    $allFiles = @()
    $drives = Get-PSDrive -PSProvider FileSystem
    
    foreach ($drive in $drives) {
        Write-Host "Searching on $($drive.Name):"
        try {
            $files = Get-ChildItem -Path $drive.Root -Recurse -Include *.exe, *.dll, *.ps1, *.bat -ErrorAction SilentlyContinue
            $allFiles += $files
        } catch {
            Write-ErrorLog "Error accessing drive $($drive.Name): $($Error[0].Message)"
        }
    }
    
    $nonSystemFiles = $allFiles | Where-Object {
        $isProtected = $false
        foreach ($protectedFolder in $protectedFolders) {
            if ($_.FullName -like "$protectedFolder\*" -or $_.FullName -eq $protectedFolder) {
                $isProtected = $true
                break
            }
        }
        return !($isProtected)
    }
    $nonSystemFiles | Format-List | Out-String | Add-Content -Path $systemFilesLog
    Add-Content -Path $generalLog -Value "$(Get-Date) - System files collected in $systemFilesLog"
} catch {
    Write-ErrorLog "Error collecting system files: $($Error[0].Message)"
}

# 3. Collect information on USB devices
Write-Host "`nCollecting information on USB devices..."
$usbDevicesLog = Join-Path $logDir "UsbDevices.txt"
if (!(Test-Path $usbDevicesLog)) {
    New-Item -ItemType File -Path $usbDevicesLog
}

try {
    $usbDevices = Get-PnpDevice -Class USB
    foreach ($device in $usbDevices) {
        $deviceInfo = [PSCustomObject]@{
            Description     = $device.Description
            Manufacturer    = $device.Manufacturer
            Model           = $device.Name
            DriverVersion   = $device.DriverVersion
            SerialNumber    = ""
        }
        
        # Get serial number using WMI
        $wmiDevice = Get-WmiObject -Class Win32_PnPEntity | Where-Object { $_.PNPDeviceID -eq $device.InstanceId }
        if ($wmiDevice) {
            # Serial number is not always available via WMI for USB devices.
            # However, for some storage devices, we can try to get the serial number via Win32_DiskDrive.
            $diskDrive = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.PNPDeviceID -like "*USB*" }
            foreach ($drive in $diskDrive) {
                if ($drive.PNPDeviceID -eq $wmiDevice.PNPDeviceID) {
                    $deviceInfo.SerialNumber = $drive.SerialNumber
                    break
                }
            }
        }
        
        $deviceInfo | Format-List | Out-String | Add-Content -Path $usbDevicesLog
    }
    Add-Content -Path $generalLog -Value "$(Get-Date) - USB devices collected in $usbDevicesLog"
} catch {
    Write-ErrorLog "Error collecting USB devices: $($Error[0].Message)"
}

# 4. Collect information on PCI devices
Write-Host "`nCollecting information on PCI devices..."
$pciDevicesLog = Join-Path $logDir "PciDevices.txt"
if (!(Test-Path $pciDevicesLog)) {
    New-Item -ItemType File -Path $pciDevicesLog
}

try {
    # Information on PCI slots
    $pciSlots = Get-WmiObject -Class Win32_SystemSlot
    foreach ($slot in $pciSlots) {
        $slotInfo = [PSCustomObject]@{
            SlotDesignation = $slot.SlotDesignation
            Tag            = $slot.Tag
            Status         = $slot.Status
            SupportsHotPlug = $slot.SupportsHotPlug
            MaxDataWidth   = $slot.MaxDataWidth
            Used           = $false
            DeviceInfo     = ""
        }
        
        # Check if a device is connected to this slot
        $devices = Get-WmiObject -Class Win32_PnPEntity | Where-Object { $_.PNPClass -eq "PCI" }
        foreach ($device in $devices) {
            if ($device.PNPDeviceID -like "*PCI*" -and $device.Status -eq "OK") {
                # Try to link the device to the slot
                # Note: Direct association between a slot and a device is not always possible via WMI
                #        because slot information is not always available in device properties.
                #        However, we can display device information if we know it's connected to a PCI slot.
                $slotInfo.Used = $true
                $slotInfo.DeviceInfo = "Vendor: $($device.Manufacturer), Model: $($device.Name)"
                break
            }
        }
        
        $slotInfo | Format-List | Out-String | Add-Content -Path $pciDevicesLog
    }
    
    # Information on PCI devices
    Get-WmiObject -Class Win32_PnPEntity | Where-Object { $_.PNPClass -eq "PCI" } | Format-List | Out-String | Add-Content -Path $pciDevicesLog
    Add-Content -Path $generalLog -Value "$(Get-Date) - PCI devices collected in $pciDevicesLog"
} catch {
    Write-ErrorLog "Error collecting PCI devices: $($Error[0].Message)"
}

# 5. Collect information on disks and volumes
Write-Host "`nCollecting information on disks and volumes..."
$disksLog = Join-Path $logDir "DisksAndVolumes.txt"
if (!(Test-Path $disksLog)) {
    New-Item -ItemType File -Path $disksLog
}

try {
    Get-Disk | Format-List | Out-String | Add-Content -Path $disksLog
    Get-Volume | Format-List | Out-String | Add-Content -Path $disksLog
    Add-Content -Path $generalLog -Value "$(Get-Date) - Disks and volumes collected in $disksLog"
} catch {
    Write-ErrorLog "Error collecting disks and volumes: $($Error[0].Message)"
}

# 6. Collect information on network connections
Write-Host "`nCollecting information on network connections..."
$networkConnectionsLog = Join-Path $logDir "NetworkConnections.txt"
if (!(Test-Path $networkConnectionsLog)) {
    New-Item -ItemType File -Path $networkConnectionsLog
}

try {
    Get-NetTCPConnection | Format-List | Out-String | Add-Content -Path $networkConnectionsLog
    Add-Content -Path $generalLog -Value "$(Get-Date) - Network connections collected in $networkConnectionsLog"
} catch {
    Write-ErrorLog "Error collecting network connections: $($Error[0].Message)"
}

# 7. Collect WMI information on processor, BIOS, and system
Write-Host "`nCollecting WMI information on processor, BIOS, and system..."
$wmiInfoLog = Join-Path $logDir "WmiInfo.txt"
if (!(Test-Path $wmiInfoLog)) {
    New-Item -ItemType File -Path $wmiInfoLog
}

try {
    Get-CimInstance -ClassName Win32_Processor | Format-List | Out-String | Add-Content -Path $wmiInfoLog
    Get-CimInstance -ClassName Win32_BIOS | Format-List | Out-String | Add-Content -Path $wmiInfoLog
    Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String | Add-Content -Path $wmiInfoLog
    Add-Content -Path $generalLog -Value "$(Get-Date) - WMI information collected in $wmiInfoLog"
} catch {
    Write-ErrorLog "Error collecting WMI information: $($Error[0].Message)"
}

# 8. Collect Windows Event logs
Write-Host "`nCollecting Windows Event logs..."
try {
    Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } | ForEach-Object {
        $logName = $_.LogName
        Write-Host "Collecting logs for $logName..."
        
        # Sanitize the log name to avoid forbidden characters
        $sanitizedLogName = Sanitize-FileName $logName
        
        $logFilePath = Join-Path $eventLogsDir "$($sanitizedLogName).txt"
        Get-WinEvent -LogName $logName -MaxEvents 100 | Format-List | Out-String | Set-Content -Path $logFilePath
        Add-Content -Path $generalLog -Value "$(Get-Date) - Windows Event logs for $logName collected in $logFilePath"
    }
} catch {
    Write-ErrorLog "Error collecting Windows Event logs: $($Error[0].Message)"
}

# 9. Collect PNP entities
Write-Host "`nCollecting PNP entities..."
$pnpEntitiesLog = Join-Path $logDir "PnpEntities.txt"
if (!(Test-Path $pnpEntitiesLog)) {
    New-Item -ItemType File -Path $pnpEntitiesLog
}

try {
    $pnpEntities = Get-WmiObject -Class Win32_PnPEntity
    $pnpEntities | Format-List | Out-String | Add-Content -Path $pnpEntitiesLog
    Add-Content -Path $generalLog -Value "$(Get-Date) - PNP entities collected in $pnpEntitiesLog"
} catch {
    Write-ErrorLog "Error collecting PNP entities: $($Error[0].Message)"
}

Write-Host "`nCollection completed. Check logs in $logDir"
