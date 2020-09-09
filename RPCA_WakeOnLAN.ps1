########################################################################################################
# Name: RPCA_WakeOnLAN.ps1
# Author: Miguel Contreras
# Version: 1.0
# Last Modified By: Miguel Conteras
# Last Modified On: 08/28/2020
#
# Purpose: Create a Wake on LAN connection for use with Remote PC Access and assign it to a new machine
#          catalog or an existing one.
#
# ******************************************************************************************************
# ********************************** PLEASE READ DISCLAIMER AT BOTTOM **********************************
# ******************************************************************************************************
#
# To run the script:
# 1) Open Powershell prompt with user that has admin rights on the CVAD site.
# 2) Set the Execution Policy accordingly to allow you to run the script. Alternatively, run the
#    following command:
#    powershell.exe -ExecutionPolicy Bypass
# 3) The script has two optional parameters:
#    > -mcState
#      Determines whether to create a new Machine Catalog or use an existing one.
#      Values: New, Existing
#
#    > -mcName
#      Name for the new Machine Catalog to be created, or, name of the existing Machine Catalog to use
#      with the new Wake on LAN connection.
#
# 4) If the parameters are not provided, the script will prompt you for these values at runtime.
#
# Examples:
#
# Without parameters:
# .\RPCA_WakeOnLAN.ps1
#
# With parameters:
# .\RPCA_WakeOnLAN.ps1 -mcState new -mcName FTL_HDX_RPCA
#
########################################################################################################

# Read parameters passed in command
Param(
    [string]$mcState,
	[string]$mcName
)

# Parameters required for connection creation. These values do not need to be changed.
[string]$hypervisorAddress = "N/A"
[string]$connectionName = "Remote PC Access Wake on LAN"
[string]$username = "woluser"
[string]$password = "wolpwd"

# Begining of script
Write-Host "`n#############################################`n" -ForegroundColor Yellow
Write-Host "  Start Remote PC Access Wake on LAN Script"
Write-Host "`n#############################################`n" -ForegroundColor Yellow

# Check if parameters were provided with script execution, and if so, whether they are valid.
if ($mcState -eq '' -or $mcState -eq $null) {
	$loop = $true
}
else {
	$mcState = $mcState.ToLower()
	if ($mcState -ne 'new' -and $mcState -ne 'existing') {
		Write-Host "Invalid mcState parameter value.`n" -ForegroundColor Red -BackgroundColor Black
		$loop = $true
	}
	else {
		$loop = $false
	}
}

# Ask whether to create a new Machine Catalog or if adding WoL to an existing Machine Catalog.
# This will be skipped if mcState parameter is provided.
while ($loop) {
	Write-Host "`nDo you wish to create a new Remote PC Access Machine Catalog, or add Wake on LAN to an existing Remote PC Access Machine Catalog? [New/Existing]: " -NoNewline
	$mcState = Read-Host
	$mcState = $mcState.ToLower()
	 
	if ($mcState -eq 'new' -or $mcState -eq 'existing') {		 
		$loop = $false
	}
	else {
		Write-Host "Invalid entry." -ForegroundColor Red -BackgroundColor Black
	}
}

# Ask for a Machine Catalog name if not available.
# This will be skipped if mcName parameter is provided.
if ($mcName -eq '' -or $mcName -eq $null) {
	$loop = $true
}
else {
	$loop = $false
}

while ($loop) {
	Write-Host "`nPlease enter the Machine Catalog name: " -NoNewline
	$mcName = Read-Host
		 
	if ($mcName -ne '' -or $mcName -ne $null) {		 
		$loop = $false
	}
	else {
		Write-Host "Invalid entry." -ForegroundColor Red -BackgroundColor Black
	}
}


#Load Citrix SnapIns to be able to create the WoL connection and catalog
Add-PSSnapIn -Name "*citrix*"

# Create hypervisor connection object
$hypHc = New-Item -Path xdhyp:\Connections `
				  -Name $connectionName `
				  -HypervisorAddress $hypervisorAddress `
				  -UserName $username `
				  -Password $password `
				  -ConnectionType Custom `
				  -PluginId VdaWOLMachineManagerFactory `
				  -CustomProperties "<CustomProperties></CustomProperties>" `
				  -Persist

if ($hypHc -eq $null)
{
    throw "Failed to create Hypervisor Connection"
}

# Create the Broker hypervisor connection and wait for it to be ready before trying to use it
$bhc = New-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid
if ($bhc -eq $null)
{
    throw "Failed to create Broker Hypervisor Connection"
}

Write-Host "Please wait..."
while (-not $bhc.IsReady)
{
    Start-Sleep -s 5
    $bhc = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid
}

# Create a new Machine Catalog or add Wake on LAN to existing Machine Catalog as specified
$hypUid = $bhc.Uid

if ($mcState -eq 'new') {
	$bcat = New-BrokerCatalog -Name $mcName `
							  -IsRemotePC $true `
							  -RemotePCHypervisorConnectionUid $hypUid `
							  -MachinesArePhysical $true `
							  -AllocationType Static `
							  -PersistUserChanges Discard `
							  -ProvisioningType Manual `
							  -SessionSupport SingleSession
	if ($bcat -eq $null)
	{
		throw "Failed to create Machine Catalog"
	}

	Write-Host "`nCreated Machine Catalog ""$mcName""" -ForegroundColor Green
}
elseif ($mcState -eq 'existing') {
	Get-BrokerCatalog -name $mcName | Set-BrokerCatalog -RemotePCHypervisorConnectionUid $hypUid
	Write-Host "`nAdded Wake on LAN connection to Machine Catalog ""$mcName""" -ForegroundColor Green
}


Write-Host "`n`n#############################################`n" -ForegroundColor Yellow
Write-Host "        Script Completed Successfully"
Write-Host "`n#############################################`n" -ForegroundColor Yellow




###########################################################################################################
# 
# *****************************************   LEGAL DISCLAIMER   *****************************************
#
# This software / sample code is provided to you “AS IS” with no representations, warranties or conditions 
# of any kind. You may use, modify and distribute it at your own risk. CITRIX DISCLAIMS ALL WARRANTIES 
# WHATSOEVER, EXPRESS, IMPLIED, WRITTEN, ORAL OR STATUTORY, INCLUDING WITHOUT LIMITATION WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NONINFRINGEMENT. Without limiting the 
# generality of the foregoing, you acknowledge and agree that (a) the software / sample code may exhibit 
# errors, design flaws or other problems, possibly resulting in loss of data or damage to property; 
# (b) it may not be possible to make the software / sample code fully functional; and (c) Citrix may, 
# without notice or liability to you, cease to make available the current version and/or any future 
# versions of the software / sample code. In no event should the software / code be used to support of 
# ultra-hazardous activities, including but not limited to life support or blasting activities. 
# NEITHER CITRIX NOR ITS AFFILIATES OR AGENTS WILL BE LIABLE, UNDER BREACH OF CONTRACT OR ANY OTHER THEORY 
# OF LIABILITY, FOR ANY DAMAGES WHATSOEVER ARISING FROM USE OF THE SOFTWARE / SAMPLE CODE, INCLUDING 
# WITHOUT LIMITATION DIRECT, SPECIAL, INCIDENTAL, PUNITIVE, CONSEQUENTIAL OR OTHER DAMAGES, EVEN IF ADVISED 
# OF THE POSSIBILITY OF SUCH DAMAGES. Although the copyright in the software / code belongs to Citrix, any 
# distribution of the code should include only your own standard copyright attribution, and not that of 
# Citrix. You agree to indemnify and defend Citrix against any and all claims arising from your use, 
# modification or distribution of the code.
###########################################################################################################

