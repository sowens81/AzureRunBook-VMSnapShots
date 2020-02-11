#Requires -Version 3.0
<#

    .DESCRIPTION

        This script will create an Azure Automation Runbook to run an VMSnapShot PowerShell script at a certin times and frequenancy.

        Dependencies: 

        An Azure Automation Account.
        User must be login into Microsoft Azure Tenant using the PowerShell Az module and the Subscription context set for the subscription that contains Azure Automation Account.

        
        Usage:

        To run the script excute AzRunBook-VMSS.ps1 "automationAccountSubscriptionName" "automationAccountResourceGroupName" "automationAccountName" "resourceSubscriptionName" "resourceGroupName" "runbookName" "startTime" "hourInterval"

    

    .PARAMETER automationAccountSubscriptionName

        [Mandatory Parameter] Name of the Azure Automation Account Subscription.
    
    .PARAMETER automationAccountResourceGroupName

        [Mandatory Parameter] Name of the Azure Automation Account Resource Group.


    .PARAMETER automationAccountName

        [Mandatory Parameter] Name of the Azure Automation Account.
    
    .PARAMETER resourceSubscriptionName

        [Mandatory Parameter] Name of the Azure Subscription where the resources reside.

    .PARAMETER resourceGroupName

        [Mandatory Parameter] Name of the Azure Resource Group where the resources reside.
    
    .PARAMETER runbookName

        [Mandatory Parameter] Name of the Azure Automation runbook.
    
    .PARAMETER startTime

    [Mandatory Parameter] A start time for the Runbook schedule, must be supplied in the following format: "01/01/2020 01:00:00".

    .PARAMETER hourInterval

    [Mandatory Parameter] Frequence the Runbook is processed in hours (int): example = 24.

    .NOTES

        AUTHOR: Steve Owens

        LASTEDIT: Feb 11, 2020

        VERSION: 1.0.0.1

#>
param(
    [string][Parameter(Mandatory = $true)] $automationAccountSubscriptionName,
    [string][Parameter(Mandatory = $true)] $automationAccountResourceGroupName,
    [string][Parameter(Mandatory = $true)] $automationAccountName,
    [string][Parameter(Mandatory = $true)] $resourceSubscriptionName,
    [string][Parameter(Mandatory = $true)] $resourceGroupName,
    [string][Parameter(Mandatory = $true)] $runbookName,
    [string][Parameter(Mandatory = $true)] $startTime,
    [int][Parameter(Mandatory = $true)] $hourInterval

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

# Sets the Azure Subscription Context
Set-AzContext -Subscription $automationAccountSubscriptionName

# Create Azure Automation Varibles
New-AzAutomationVariable -Name automationAccountSubscriptionName, -Value $automationAccountSubscriptionName, -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Encrypted 0
New-AzAutomationVariable -Name automationAccountResourceGroupName -Value $automationAccountResourceGroupName -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Encrypted 0
New-AzAutomationVariable -Name automationAccountName -Value $automationAccountName -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Encrypted 0
New-AzAutomationVariable -Name subscriptionName -Value $resourceSubscriptionName -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Encrypted 0
New-AzAutomationVariable -Name resourceGroupName -Value $resourceGroupName -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Encrypted 0

# Creates a new Azure Automation Runbook
New-AzAutomationRunbook -Name "$runbookName - $resourceGroupName" -Type PowerShell -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName

# Imports a PowerShell Script to an Automation Runbook
Import-AzAutomationRunbook -Type PowerShell -Path "runbook/VMSnapShot.ps1"  -Name "$runbookName" -Description "Automation Run Book to create VM Disk SnapShots" -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Force

# Publishes the Automation runbook
Publish-AzAutomationRunbook -Name "$runbookName - $resourceGroupName" -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName

# Creates a re-usable Automation Runbook Schedule
New-AzureRMAutomationSchedule –Name "Schedule - Every $hourInterval House" -StartTime $startTime -HourInterval $hourInterval  -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName

# Register an Automation Runbook Schedule with an Automation Runbook
Register-AzAutomationScheduledRunbook -Name "$runbookName - $resourceGroupName" -AutomationAccountName $automationAccountName -ResourceGroupName $automationAccountResourceGroupName -ScheduleName "Schedule - Every $hourInterval House"

