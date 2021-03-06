# Azure Automation - Schedule Disk Snapshot Run book

## Overview

These PowerShell Modules will import the required Azure Az PowerShell modules to an existing Azure Automation Account. They will also create scheduled runbook to perform Azure Disks Snapshots on a specific resource group.

### Dependancies

You must have the Azure Az PowerShell module installed locally to run the scripts.

    Open PowerShell > Run command following command

    For Current Context User: Install-Module -Name Az -AllowClobber -Scope CurrentUser
    or
    For All Users: Install-Module -Name Az -AllowClobber -Scope AllUsers

An Azure Automation Account - [Setup an Azure Automation Account](https://docs.microsoft.com/en-us/azure/automation/automation-create-standalone-account)

### Usage

This script is currently not working remotely, use manual aproach below. - Run the AzureAutomation-ModuleImport.ps1 script first to import the modules - see script documentation for more details

Install the following Az Modules via the PowerShell Gallery Azure Automation Installer
* [Az.Automation](https://www.powershellgallery.com/packages/Az.Automation/)
* [Az.Profile](https://www.powershellgallery.com/packages/Az.Profile/)
* [Az.Compute](https://www.powershellgallery.com/packages/Az.Compute/)
* [Az.Resources](https://www.powershellgallery.com/packages/Az.Resources/)
* [Az.Accounts](https://www.powershellgallery.com/packages/Az.Accounts/)

Run the AzRunBook-VMSS.ps1 for as many different Snapshot runbooks as you need (provide different names for each runbook) - see script documentation for more details

## Authors

* **Steve Owens** - *Initial work* - [sowens81](https://github.com/sowens81)

## Acknowledgments

* **Matt Perry** - [dillorscroft](https://github.com/dillorscroft)
* **Microsoft Automation Team** [Update-ModulesInAutomationToLatestVersion](https://github.com/azureautomation/runbooks/blob/master/Utility/Update-ModulesInAutomationToLatestVersion.ps1)
