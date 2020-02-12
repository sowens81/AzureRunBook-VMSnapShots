#Requires -Version 3.0

<#

    .DESCRIPTION

        This script will deploy the Azure Az module to a Azure Automation account.

        Dependencies: 

        User must be login into Microsoft Azure Tenant using the PowerShell Az module and the Subscription context set for the subscription that contains Azure Automation Account.

        Usage:

        To run the script excute AzureAutomationAzImport.ps1 "automationAccountName" "resourceGroupName"

        Add additional Azure Az Modules to the variable modules below.

    

    .PARAMETER automationAccountName

        [Mandatory Parameter] Name of the Azure Automation Account to deploy the module to.


    .PARAMETER resourceGroupName

        [Mandatory Parameter] Name of the Resource Group where the Azure Automation Account is located.


    .NOTES

        AUTHOR: Steve Owens

        LASTEDIT: Feb 11, 2020

        VERSION: 1.0.0.1

#>
param(
      [string][Parameter(Mandatory = $true)] $automationAccountName,
      [string][Parameter(Mandatory = $true)] $resourceGroupName
)

 $ErrorActionPreference = 'Stop'
 
 Try {
    $s = Get-AzSubscription
  } Catch {
    if ($_ -like "*Connect-AzAccount to login*") {
      Write-Host "Please run Connect-AzAccount to conenct to Azure!"
      Exit
    }
  }

$modules = @{"az.profile" = "0.7.0"; "az.automation" = "1.3.5"; "az.accounts" = "1.7.1"; "az.resources" = "1.9.1"; "az.compute" = "3.4.0"}

$ModulesImported = @()

function _doImport {
    param(
        [Parameter(Mandatory=$true)]
        [String] $ResourceGroupName,

        [Parameter(Mandatory=$true)]
        [String] $AutomationAccountName,
    
        [Parameter(Mandatory=$true)]
        [String] $ModuleName,

        # if not specified latest version will be imported
        [Parameter(Mandatory=$false)]
        [String] $ModuleVersion
    )

          $githubURI = "https://github.com/sowens81/AzureRunBook-VMSnapShots/blob/master/PowerShellModules/$ModuleName.$ModuleVersion.nupkg?raw=true"

          $ActualUrl = $githubURI

           Write-Host "Importing $ModuleName module of version $ModuleVersion from $ActualUrl to Automation"

            $AutomationModule = New-AzAutomationModule `
                -ResourceGroupName $ResourceGroupName `
                -AutomationAccountName $AutomationAccountName `
                -Name $ModuleName `
                -ContentLink $ActualUrl

            while(
                $AutomationModule.ProvisioningState -ne "Created" -and
                $AutomationModule.ProvisioningState -ne "Succeeded" -and
                $AutomationModule.ProvisioningState -ne "Failed"
            )
            {
                Write-Host "Polling for module import completion"
                Start-Sleep -Seconds 10
                $AutomationModule = $AutomationModule | Get-AzAutomationModule
            }

            if($AutomationModule.ProvisioningState -eq "Failed") {
                Write-Error "Importing $ModuleName module to Automation failed."
            }
            else {
                Write-Host "Importing $ModuleName module to Automation succeeded."
            }
}

#Import Each Azure Az Module
foreach ($h in $modules.Keys) {
  $modName = $h
  $mVersion = $modules[$h]
  Write-Host "Module Name: $modName, Module Version: $mVersion"
  _doImport `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -ModuleName $modName `
    -ModuleVersion $mVersion
}
