# Domain Joined Payload Detonation Lab
# Setup for MS Eval ISOs
# Download here https://www.microsoft.com/en-us/evalcenter
# Added VLAN 100 for VMs
# Based on https://trustedsec.com/blog/offensive-lab-environments-without-the-suck


New-LabDefinition -Name PayloadLab -VmPath D:\LAB-VMs -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name PayloadLab -AddressSpace 10.100.100.0/24
Add-LabVirtualNetworkDefinition -Name 'VM Lab Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Embedded FlexibleLOM 1 Port 1'}

Add-LabMachineDefinition -Name Payload-DC -Memory 4GB -OperatingSystem 'Windows Server 2016 Standard Evaluation (Desktop Experience)' -Roles RootDC -Network PayloadLab -DomainName client.local

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch PayloadLab
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'VM Lab Switch' -UseDhcp -AccessVLANID 100
Add-LabMachineDefinition -Name Payload-Router -Memory 1GB -OperatingSystem 'Windows Server 2016 Standard Evaluation (Desktop Experience)' -Roles Routing -NetworkAdapter $netAdapter -DomainName client.local
Add-LabMachineDefinition -Name Payload-Client -Memory 4GB -Network PayloadLab -OperatingSystem 'Windows 10 Enterprise Evaluation' -DomainName client.local

Install-Lab

#########################################
# Optional post-deployment configuration:

$labVMs = Get-LabVM
foreach ($vm in $labVMs) {
    Copy-LabFileItem -Path C:\LabSources\Tools\SysInternals\Winobj64.exe -ComputerName $vm -DestinationFolderPath C:\users\Administrator\Desktop\ -verbose -PassThru
    Copy-LabFileItem -Path C:\LabSources\Tools\SysInternals\procexp64.exe -ComputerName $vm -DestinationFolderPath C:\users\Administrator\Desktop\ -verbose -PassThru
    Copy-LabFileItem -Path C:\LabSources\Tools\SysInternals\dbgview64.exe -ComputerName $vm -DestinationFolderPath C:\users\Administrator\Desktop\ -verbose -PassThru
    
    ######################################################################
    ### Optional Payload/Install methods for quick deployment and testing
    ######################################################################
    #Copy-LabFileItem -Path C:\LabSources\Tools\payload\payload.exe -ComputerName $vm -DestinationFolderPath c:\temp -verbose -PassThru
    #Copy-LabFileItem -Path C:\LabSources\Tools\payload\setup.ps1 -ComputerName $vm -DestinationFolderPath c:\temp\ -verbose -PassThru
    #Invoke-LabCommand -ActivityName 'Install service ps1' -ScriptBlock { . C:\Temp\setup.ps1 } -ComputerName $vm  -PassThru 
}

foreach ($vm in $labVMs) {
    # reboot
    Restart-LabVm -ComputerName $vm -Wait -NoDisplay
}

######################################################################################################
# Set optional exclusions for Defender

foreach ($vm in $labVMs) {
     Invoke-LabCommand -ActivityName 'Add Exception for Payload Directory' -ComputerName $vm -ScriptBlock { Add-MpPreference -ExclusionPath 'C:\temp\'} -PassThru 
     Invoke-LabCommand -ActivityName 'Temporarily disable realtime-protection' -ComputerName $vm -ScriptBlock { Set-MpPreference -DisableRealtimeMonitoring $false} -PassThru
}

Show-LabDeploymentSummary -Detailed
