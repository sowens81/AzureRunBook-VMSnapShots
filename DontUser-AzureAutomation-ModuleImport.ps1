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

$modules = @{"az.profile" = "0.7.0"; "az.automation" = "1.3.5"; "az.accounts" = "1.7.1"; "az.resources" = "1.10.0"; "az.compute" = "3.4.0"}

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
          
    $Url = "https://www.powershellgallery.com/api/v2/Search()?`$filter=IsLatestVersion&searchTerm=%27$ModuleName%27&targetFramework=%27%27&includePrerelease=false&`$skip=0&`$top=40" 
    $SearchResult = Invoke-RestMethod -Method Get -Uri $Url -UseBasicParsing

    if($SearchResult.Length -and $SearchResult.Length -gt 1) {
        $SearchResult = $SearchResult | Where-Object -FilterScript {
            return $_.properties.title -eq $ModuleName
        }
    }
    


    if(!$SearchResult) {
       Write-Error "Could not find module '$ModuleName' on PowerShell Gallery."
        
    }
    else {
        $ModuleName = $SearchResult.properties.title # get correct casing for the module name
        $PackageDetails = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $SearchResult.id 
    
        if(!$ModuleVersion) {
            # get latest version
            $ModuleVersion = $PackageDetails.entry.properties.version
        }

        $ModuleContentUrl = "https://www.powershellgallery.com/api/v2/package/$ModuleName/$ModuleVersion"

        # Test if the module/version combination exists
        try {
            Invoke-RestMethod $ModuleContentUrl -ErrorAction Stop | Out-Null
            $Stop = $False
        }
        catch {
            Write-Error "Module with name '$ModuleName' of version '$ModuleVersion' does not exist. Are you sure the version specified is correct?"
            $Stop = $True
        }

        if(!$Stop) {

            # Make sure module dependencies are imported
            $Dependencies = $PackageDetails.entry.properties.dependencies

            if($Dependencies -and $Dependencies.Length -gt 0) {
                $Dependencies = $Dependencies.Split("|")

                # parse depencencies, which are in the format: module1name:module1version:|module2name:module2version:
                $Dependencies | ForEach-Object {

                    if($_ -and $_.Length -gt 0) {
                        $Parts = $_.Split(":")
                        $DependencyName = $Parts[0]
                        $DependencyVersion = $Parts[1]

                        # check if we already imported this dependency module during execution of this script
                        if(!$ModulesImported.Contains($DependencyName)) {

                            $AutomationModule = Get-AzAutomationModule `
                                -ResourceGroupName $ResourceGroupName `
                                -AutomationAccountName $AutomationAccountName `
                                -Name $DependencyName `
                                -ErrorAction SilentlyContinue
    
                            # check if Automation account already contains this dependency module of the right version
                            if((!$AutomationModule) -or $AutomationModule.Version -ne $DependencyVersion) {
                                
                               Write-Host "Importing dependency module $DependencyName of version $DependencyVersion first."

                                # this dependency module has not been imported, import it first
                                _doImport `
                                    -ResourceGroupName $ResourceGroupName `
                                    -AutomationAccountName $AutomationAccountName `
                                    -ModuleName $DependencyName `
                                    -ModuleVersion $DependencyVersion

                               $ModulesImported += $DependencyName
                            }
                        }
                    }
                }
            }
            
            Find the actual blob storage location of the module
            do {
                $ActualUrl = $ModuleContentUrl
                Write-Host "Error Happens here with Invoke-WebRequest"
                $ModuleContentUrl = (Invoke-WebRequest -Uri $ModuleContentUrl -MaximumRedirection 0 -UseBasicParsing -ErrorAction Ignore).Headers.Location 
            } while($ModuleContentUrl -ne $Null)
            
           $ActualUrl = $ModuleContentUrl

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
    }
}

#Import Each Azure Az Module
foreach ($h in $modules.Keys) {
  $modName = $h
  $mVersion = $modules[$h]
  _doImport `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -ModuleName $modName `
    -ModuleVersion $mVersion
}
