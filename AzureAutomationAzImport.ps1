#Requires -Version 3.0
<#

    .DESCRIPTION

        This script will deploy the Azure Az module to a Azure Automation account.

        Dependencies: 

        User must be login into Microsoft Azure Tenant using the PowerShell Az module and the Subscription context set for the subscription that contains Azure Automation Account.

        Usage:

        To run the script excute AzureAutomationAzImport.ps1 "AutomationAccountName" "ResourceGroupName"

    

    .PARAMETER AutomationAccountName

        [Mandatory Parameter] Name of the Azure Automation Account to deploy the module to.


    .PARAMETER ResourceGroupName

        [Mandatory Parameter] Name of the Resource Group where the Azure Automation Account is located.


    .NOTES

        AUTHOR: Steve Owens

        LASTEDIT: Feb 11, 2020

        VERSION: 1.0.0.1

#>

param(
    [string][Parameter(Mandatory = $true)] $AutomationAccountName,
    [string][Parameter(Mandatory = $true)] $ResourceGroupName
 )

 $ErrorActionPreference = 'Stop'

 Try {
    Get-AzSubscription
  } Catch {
    if ($_ -like "*Connect-AzAccount to login*") {
      Write-Host "Please run Connect-AzAccount to conenct to Azure!"
      Exit
    }
  }

$modules = "Az.Profile", "Az.Accounts","Az.Resources", "Az.Compute"
$moduleUri = "https://www.powershellgallery.com/api/v2/package/"


foreach($module in $modules)
{
  New-AzAutomationModule -Name $module -ContentLinkUri $ModuleUri+$module -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
}
