#Requires -Version 3.0

<#

    .DESCRIPTION

        This script will perform an Azure Virtual Machine Disk Snap Shot for the disk resource with a specified resource group.

        Dependencies: 

    
        An Azure Automation Account with a Run As Account enabled.
        All Disk resources that required snapshots in resource group must Included the following Tag:
        Key=SnapShot Value=True
        An Azure Automation Runbook parameter - subscriptionName
        An Azure Automation Runbook parameter - resourceGroupName
        An Azure Automation Runbook parameter - resourceGroupName
        An Azure Automation Runbook parameter - resourceGroupName
        An Azure Automation Runbook parameter - resourceGroupName
        
        Usage:

        n/a - part of an Azure Runbook
    
    .PARAMETER subscriptionName

        [Mandatory Parameter] Name of the Azure Automation Account to deploy the module to.
    
    .PARAMETER resourceGroupName

        [Mandatory Parameter] Name of the Azure Automation Account to deploy the module to.
    
    .PARAMETER subscriptionName

        [Mandatory Parameter] Name of the Azure Automation Account to deploy the module to.


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

$resourceSubscriptionName = (Get-AzAutomationVariable -Name  subscriptionName -ResourceGroupName $ -AutomationAccountName $).Value
$resourceGroupName = (Get-AzAutomationVariable -Name  subscriptionName -ResourceGroupName $ -AutomationAccountName $).Value


$AzureContext = Select-AzSubscription -Subscription $resourceSubscriptionName
$Disks=Get-AzDisk -AzContext $AzureContext | Select Name,Tags,Id,Location,ResourceGroupName | Where-Object {$_.ResourceGroupName -eq $resourceGroupName}

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