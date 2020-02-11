#Requires -Version 3.0

<#

    .DESCRIPTION

        This script will perform an Azure Virtual Machine Disk Snapshot for the disk resource with a specified resource group and subscription, as long as the Azure Automtion Account Service Principle has Access.

        Dependencies: 

    
        An Azure Automation Account with a Run As Account enabled.
        
        All Disk resources that required snapshots in resource group must Included the following Tag:
        Key=SnapShot Value=True

        An Azure Automation Runbook parameter - automationAccountSubscriptionName
        An Azure Automation Runbook parameter - automationAccountResourceGroupName
        An Azure Automation Runbook parameter - automationAccountName
        An Azure Automation Runbook parameter - resourceSubscriptionName
        An Azure Automation Runbook parameter - resourceGroupName
        
        Usage:

        n/a - part of an Azure Runbook
    
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


    .NOTES

        AUTHOR: Steve Owens

        LASTEDIT: Feb 11, 2020

        VERSION: 1.0.0.1

#>

$ErrorActionPreference = 'Stop'

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

$connection = Get-AutomationConnection -Name 'AzureRunAsConnection'

# Wrap authentication in retry logic for transient network failures
$logonAttempt = 0
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationID $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}

# Import the Azure Automation Variables
$rSName = (Get-AzAutomationVariable -Name resourceSubscriptionName -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountSubscriptionName).Value
$rGName = (Get-AzAutomationVariable -Name resourceGroupName -ResourceGroupName $automationAccountResourceGroupName -AutomationAccountName $automationAccountSubscriptionName).Value

# Set the Azure Context for the resource to be worked on
$AzureContext = Select-AzSubscription -Subscription $rSName

# Create a Disk object with all disks where where tag Snapshot = True
$Disks=Get-AzDisk -AzContext $AzureContext | Select Name,Tags,Id,Location,ResourceGroupName | Where-Object {$_.ResourceGroupName -eq $rGName}

# Take a snapshot of all disks within the Disk object
foreach($disk in $Disks) 
{ 
    foreach($tag in $disk.Tags) 
        { 
            if($tag.Snapshot -eq 'True') 
            {
                $snapshotconfig = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $disk.Location -AccountType Standard_LRS;$SnapshotName=$disk.Name+(Get-Date -Format "yyyy-MM-dd");New-AzSnapshot -Snapshot $snapshotconfig -SnapshotName $SnapshotName -ResourceGroupName $disk.ResourceGroupName 
            }
        }       
}