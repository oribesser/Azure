function Remove-AzVMClean
{
    <#
    .SYNOPSIS
    Removes an Azure VM including its NICs, Public IPs and disks.

    .PARAMETER ResourceGroupName
    the resource group of the VM to remove.

    .PARAMETER Name
    The name of the VM o remove.

    .PARAMETER Force
    Don't ask for confirmation (by default, asks for confirmation for any removal).

    .EXAMPLE
    Get-AzVm -ResourceGroupName rgname -Name vmname | Remove-AzVMClean -WhatIf
    Get the VM and pipe it to this function, use WhatIf to only display what would be removed.

    .EXAMPLE
    Remove-AzVMClean -ResourceGroupName rgname -Name vmname -Force -Verbose
    Remove the VM and its associated NICs, Public IPs and disks, skip confirmation and display Verbose output to follow progress.

    .NOTES
    Ori Besser
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$Force
    )

    process
    {
        $vm = Get-AzVm -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction Stop
        $nicIds = @($vm.NetworkProfile.NetworkInterfaces.Id)
        $nics = Get-AzNetworkInterface | Where-Object { $_.Id -in $nicIds }
        $publicIpIds = @($nics.IpConfigurations.PublicIpAddress.Id)
        $publicIps = Get-AzPublicIpAddress | Where-Object { $_.Id -in $publicIpIds }
        $disks = Get-AzDisk | Where-Object { $_.ManagedBy -eq $vm.Id }

        Write-Verbose "Removing the VM [$($vm.Name)], Resource Group [$($vm.ResourceGroupName)]"
        $vm | Remove-AzVM -Force:$Force
        if ($nics)
        {
            Write-Verbose "Removing VM network interfaces [$($nics.Name)]"
            $nics | Remove-AzNetworkInterface -Force:$Force
        }

        if ($publicIps)
        {
            Write-Verbose "Removing VM NICs public IPs [$($publicIps.IpAddress)]"
            $publicIps | Remove-AzPublicIpAddress -Force:$Force
        }

        if ($disks)
        {
            Write-Verbose "Removing VM disks [$($disks.Name)]"
            $disks | Remove-AzDisk -Force:$Force
        }
    }

}