#Requires -Version 3.0

<#

    .DESCRIPTION

        This script will perform an Azure Virtual Machine Disk Snap Shot for the disk resource with a specified resource group.

        Dependencies: 

    
        An Azure Automation Account with a Run As Account enabled.
        All Disk resources that required snapshots in resource group must Included the following Tag:
        Key=SnapShot Value=True
        
        Usage:

        To run the script excute AzRunBook-VMSnapShot.ps1 "subscriptionName" "resourceGroupName"

        
    .PARAMETER subscriptionName

        [Mandatory Parameter] Name of the Azure Subscription where the resources reside.

    .PARAMETER resourceGroupName

        [Mandatory Parameter] Name of the Azure Resource Group where the resources reside.


    .NOTES

        AUTHOR: Steve Owens

        LASTEDIT: Feb 11, 2020

        VERSION: 1.0.0.1

#>

param(
    [string][Parameter(Mandatory = $true)]$subscriptionName,
    [string][Parameter(Mandatory = $true)]$ResourceGroupName
)

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


$AzureContext = Select-AzSubscription -Subscription $subscriptionName
$Disks=Get-AzDisk -AzContext $AzureContext | Select Name,Tags,Id,Location,ResourceGroupName | Where-Object {$_.ResourceGroupName -eq $ResourceGroupName}

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