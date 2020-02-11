#Requires -Version 3.0
$ErrorActionPreference = 'Stop'
<#

    .DESCRIPTION

        This script will perform an Azure Virtual Machine Disk Snap Shot for the disk resource with a specified resource group.

        Dependencies: 

        
        An Azure Automation Account with a Run As Account enabled.
        
        Usage:

        To run the script excute AzRunBook-VMSnapShot.ps1 "clientID" "key" "tenantID" "subscriptionName" "resourceGroupName"

    

    .PARAMETER clientID

        [Mandatory Parameter] Azure Service Principle Client Id.
    
    .PARAMETER key

        [Mandatory Parameter] Azure Service Principle secure key/password


    .PARAMETER tenantID

        [Mandatory Parameter] ID of the Azure Tenant where the resources reside.
    
    .PARAMETER subscriptionName

        [Mandatory Parameter] Name of the Azure Subscription where the resources reside.

    .PARAMETER resourceGroupName

        [Mandatory Parameter] Name of the Azure Resource Group where the resources reside.
    
    .PARAMETER AutomationAccountName

        [Mandatory Parameter] Name of the Azure Automation Account to deploy the module to.

    


    .NOTES

        AUTHOR: FistName LastName

        LASTEDIT: Feb 11, 2020

        VERSION: 1.0.0.1

#>
param(
    [Parameter(Mandatory = $true)]
    [string]$tenantID,
    [Parameter(Mandatory = $true)]
    [string]$subscriptionName,
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName
 )

Get-AzSubscription $SubscriptionId | Select-AzSubscription
New-AzAutomationVariable -Name SubscriptionId -Value $clientID -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -Encrypted 0
New-AzAutomationVariable -Name SubscriptionId -Value $key -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -Encrypted 0
New-AzAutomationVariable -Name SubscriptionId -Value $tenantID -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -Encrypted 0
New-AzAutomationVariable -Name SubscriptionId -Value $subscriptionName -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -Encrypted 0
New-AzAutomationVariable -Name SubscriptionId -Value $SubscriptionId -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -Encrypted 0
New-AzAutomationVariable -Name SubscriptionId -Value $SubscriptionId -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -Encrypted 1

Import-AzAutomationRunbook -Type PowerShell -Path "VMSnapShot.ps1"  -Name "Virtual-Machine-Snapshot" -Description "Automation Run Book to Backup Virtual Machines" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName
Publish-AzAutomationRunbook -Name "Scale-APIM-Down" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName
$StartTime = Get-Date "18:00"
if($StartTime -le (Get-Date)){
    $StartTime = $StartTime.AddDays(1)
}
$EndTime = $StartTime.AddYears(100)
Write-Host $StartTime
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroup -Name "Daily Evening Schedule" -StartTime $StartTime -ExpiryTime $EndTime -DayInterval 1
$StartTime = Get-Date "8:00"
if($StartTime -le (Get-Date)){
    $StartTime = $StartTime.AddDays(1)
}
$EndTime = $StartTime.AddYears(100)
Write-Host $StartTime
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroup -Name "Daily Morning Schedule" -StartTime $StartTime -ExpiryTime $EndTime -DayInterval 1
Register-AzAutomationScheduledRunbook -RunbookName "Scale-APIM-Up" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -ScheduleName "Daily Morning Schedule"
Register-AzAutomationScheduledRunbook -RunbookName "Scale-APIM-Down" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccountName -ScheduleName "Daily Evening Schedule"