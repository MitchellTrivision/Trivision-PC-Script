#Schakelt BitLocker in op de C schijfals dit niet ingeschakeld is
if(((Get-BitLockerVolume | Where-Object -Property MountPoint -Contains C:).ProtectionStatus) -eq 'Off'){
Enable-BitLocker -MountPoint "C:" -RecoveryPasswordProtector
}
##Slaat specs en bitlocker op als variabele
$Model            = (Get-CimInstance Win32_ComputerSystem).Model
$CPU              = (Get-CimInstance Win32_Processor -Property Name).Name
$SerieNummer      = (Get-CimInstance Win32_BIOS).SerialNumber
$SchijfNaam       = (Get-CimInstance Win32_DiskDrive | Where-Object -Property DeviceID -Contains \\.\PHYSICALDRIVE0).Caption
$SchijfGrootte    = [math]::Round((Get-CimInstance Win32_DiskDrive -Filter 'DeviceID="\\\\.\\PHYSICALDRIVE0"').Size / 1GB)
$TotaalGeheugen   =  Write-Output [math]::Round((Get-CimInstance -Class CIM_PhysicalMemory -ErrorAction Stop | Measure-Object Capacity -Sum).Sum / 1GB) "GB"
$DimmType1        = (Get-CimInstance -Class CIM_PhysicalMemory).SMBIOSMemoryType | Select-Object -First 1
$DimmType2        = (Get-CimInstance -Class CIM_PhysicalMemory).SMBIOSMemoryType | Select-Object -Skip 1
$BitLockerID      = (Get-BitLockerVolume -MountPoint C).KeyProtector | Where-Object RecoveryPassword | Select-Object -ExpandProperty KeyProtectorId
$BitLockerSleutel = (Get-BitLockerVolume -MountPoint C).KeyProtector | Where-Object RecoveryPassword | Select-Object -ExpandProperty RecoveryPassword
##
###Output niks na $TotaalGeheugen in $Specs als er 2 verschillende ramtype's in 1 systeem zitten bijv. ddr4 en lpddr4
if($DimmType1 -eq $DimmType2){
    $GeheugenMHZ  =  Write-Output "@"(Get-CimInstance -Class CIM_PhysicalMemory -ErrorAction Stop | Measure-Object Speed -Minimum).Minimum "MHZ"
}
elseif(-not $DimmType2){
    $GeheugenMHZ  =  Write-Output "@"(Get-CimInstance -Class CIM_PhysicalMemory -ErrorAction Stop | Measure-Object Speed -Minimum).Minimum "MHZ"
}
else{
    $GeheugenMHZ  =  $null
}
###
#

#Verandert systeem naam
$NewName = Read-Host -Prompt "Wat is de naam van de PC?(bijv. WS01 of LT01)"
Rename-Computer -NewName "$NewName"
#

#Output bitlocker id, bitlocker key, PC model, CPU, serienummer, RAM info en drive info naar een csv bestand
$Specs = [PSCustomObject]@{
    Model                       = "$Model"
    CPU                         = "$CPU"
    SerieNummer                 = "$SerieNummer"
    SchijfInfo                  = "$SchijfGrootte GiB $SchijfNaam"
    RAMInfo                     = "$TotaalGeheugen $GeheugenMHZ"
    "Bitlocker ID"              = "$BitlockerID"
    "Bitlocker Herstel Sleutel" = "$BitLockerSleutel"
}
$specs | Export-Csv H:\PcInfo$NewName.csv -NoTypeInformation
#

#Verandert tijdzone
tzutil /s "W. Europe Standard Time"
#

#Verwijdert Windows.old als het bestaat
if ((Test-Path -Path 'C:\Windows.old' -PathType Container) -eq $true){
TAKEOWN /f C:\Windows.old\*.*
ICACLS C:\Windows.old\*.* /Grant 'System:(F)'
Remove-Item C:\Windows.old\*.*
}
#

#Zet UAC uit
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
#

#Start volgende script
powershell.exe -ExecutionPolicy UnRestricted -File H:\Resources\nietgebruiken.ps1
#