#Requires -Version 3.0

<#

    .DESCRIPTION

        This script will perform an Azure Virtual Machine Disk Snap Shot for the disk resource with a specified resource group.

        Dependencies: 

        An Azure Service Principle.
        An Azure Automation Account.
        
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

    


    .NOTES

        AUTHOR: FistName LastName

        LASTEDIT: Feb 11, 2020

        VERSION: 1.0.0.1

#>

param(
    [string][Parameter(Mandatory = $true)]$clientID,
    [string][Parameter(Mandatory = $true)]$key,
    [string][Parameter(Mandatory = $true)]$tenantID,
    [string][Parameter(Mandatory = $true)]$subscriptionName,
    [string][Parameter(Mandatory = $true)]$ResourceGroupName
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

$SecurePassword = $key | ConvertTo-SecureString -AsPlainText -Force
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $clientID, $SecurePassword
Add-AzAccount -Credential $Cred -Tenant $tenantID -ServicePrincipal;
Set-AzContext -Subscription $subscriptionName
$Disks=Get-AzDisk | Select Name,Tags,Id,Location,ResourceGroupName | Where-Object {$_.ResourceGroupName -eq $ResourceGroupName}

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