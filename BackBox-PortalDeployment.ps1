[CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # VHD source URI
        $sourceVHDURI = 'https://alon111.blob.core.windows.net/bbimage/newVHDimage.vhd',
        
        # VHD sas token
        $sasToken = 'sp=r&st=2020-08-24T09:42:04Z&se=2021-08-24T17:42:04Z&spr=https&sv=2019-12-12&sr=b&sig=A%2BP4d3yptD1B5JNPmfvT0MCGFc7YpSbDQF1aMdWx620%3D'
    )
    
    
    $location= read-host "Please enter location"
    $ErrorActionPreference = 'stop'
    $resourceGroupName = "RG-BackBox"
    $storageaccountname = "sluhndevbackboxstg"
    $contname = "$storageaccountname-cont"
    $vhd = Split-Path -Leaf $sourceVHDURI 
   
    if (!(Get-AzureRmResourceGroup -name $resourceGroupName -ErrorAction SilentlyContinue )) {
        write-output "Creating New Resource group: $resourceGroupName"
        $RG = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
    } else {$RG = Get-AzureRmResourceGroup -name $resourceGroupName}
    
    write-output "Creating New Storageaccount: $storageaccountname"
    $stg = New-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storageaccountname -SkuName Standard_LRS -Location $location -Kind StorageV2 -AccessTier Cool
    write-output "Creating New Container: $contname"
    $cont = New-AzureRmStorageContainer -StorageAccountName $storageaccountname -ResourceGroupName $rg.ResourceGroupName -Name $contname

    Write-Output "Start Time: $(get-date)"
    Write-Output "Start copy backbox VHD"

    $blob = Start-AzureStorageBlobCopy -AbsoluteUri ($sourceVHDURI + "?" + $sasToken) -DestContainer $cont.Name -DestBlob $vhd -DestContext $stg.Context
    $blob| Get-AzureStorageBlobCopyState

    Do {Write-Output "copy status is: $(($blob| Get-AzureStorageBlobCopyState).Status)"; sleep -Seconds 10} Until (($blob| Get-AzureStorageBlobCopyState).Status -ne "Uploading The BackBox VHD Image File To Your Azure Account.")
    Write-Output "End Time: $(get-date)"

    $newUri = "$($blob.context.BlobEndPoint)" + "$($cont.name)/" + "$vhd" #+ $sas
    Write-Output "New URI: $newUri"  
