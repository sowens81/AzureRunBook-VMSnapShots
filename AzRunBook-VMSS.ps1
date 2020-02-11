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

# Function to check if a Automation Account Varible exists before creation
function CreateAzAutomationVarible([string]$parameterName ,[string] $parameterVale)
{
    Write-Host "Check and Create Azure Automation Parameter: $parameterName..."
    try {
        New-AzAutomationVariable -Name $parameterName -Value $parameterVale, -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Encrypted 0

    }
    catch {
        if ($_ -like "The variable already exists.") {
            Write-Host "The variable $parameterName already exists.."
        
        }

    }
}

# Function to check if a Automation Account Runbook already exists, the create and publish it.
function CreateAzAutomationRunBook([string]$rName)
{
    Write-Host "Check and Create Azure Automation Runbook: $rName - $resourceGroupName..."
    try {
        New-AzAutomationRunbook -Name "$rName-$resourceGroupName" -Type PowerShell -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName
    }
    catch {
        if ($_ -like "The Runbook already exists") {
            Write-Host 'The run book "'$rName-$resourceGroupName'" already exists..'
            Exit
        }

    }
    Write-Host "Importing Azure Automation Runbook Script: $rName - $resourceGroupName..."
    # Imports a PowerShell Script to an Automation Runbook
    Import-AzAutomationRunbook -Type PowerShell -Path "runbook/VMSnapShot.ps1"  -Name "$rName-$resourceGroupName" -Description "Automation Run Book to create VM Disk SnapShots" -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName -Force

    Write-Host "Publishing Azure Automation Runbook: $rName - $resourceGroupName..."
    # Publishes the Automation runbook
    Publish-AzAutomationRunbook -Name "$rName-$resourceGroupName" -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName
}

# Function to check if a Automation Account Schedule already exists.
function CreateAzAutomationSchedule([string]$sTime, [int]$interval)
{
    Write-Host "Check and Create Azure Automation Schedule: Schedule - Every $interval House..."
    try {
        New-AzAutomationSchedule –Name "Schedule - Every $interval House" -StartTime $sTime -HourInterval $interval  -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountName
    }
    catch {
        if ($_ -like "A job schedule for the specified runbook and schedule already exists") {
            Write-Host 'The run book "'$rName-$resourceGroupName'" already exists..'
        }

    }
    
}

# Create Azure Automation Varibles
CreateAzAutomationVarible -parameterName "automationAccountSubscriptionName" -parameterVale $automationAccountSubscriptionName
CreateAzAutomationVarible -parameterName "automationAccountResourceGroupName" -parameterVale $automationAccountResourceGroupName
CreateAzAutomationVarible -parameterName "automationAccountName" -parameterVale $automationAccountName
CreateAzAutomationVarible -parameterName "subscriptionName" -parameterVale $resourceSubscriptionName
CreateAzAutomationVarible -parameterName "resourceGroupName" -parameterVale $resourceGroupName

# Creates a new Azure Automation Runbook
CreateAzAutomationRunBook -rName $runbookName

# Creates a re-usable Automation Runbook Schedule
CreateAzAutomationSchedule -sTime $startTime -interval $hourInterval

# Register an Automation Runbook Schedule with an Automation Runbook
Write-Host "Registring Azure Automation Schedule with Runbook: $runbookName-$resourceGroupName..."
Register-AzAutomationScheduledRunbook -Name "$runbookName-$resourceGroupName" -AutomationAccountName $automationAccountName -ResourceGroupName $automationAccountResourceGroupName -ScheduleName "Schedule - Every $hourInterval House"
