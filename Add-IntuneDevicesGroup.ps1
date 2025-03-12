# Description: This script adds a list of devices to an Intune group.
Function Invoke-BatchRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [array]$ItemsArray
    )
    
    $batchId = 0
    $batchTable = @{
        
        requests = @()
    }

    
        $headers = @{
            "Content-Type" = "application/json"
        }
        foreach ($item in $ItemsArray) {
            $batchid++
            $deviceQuery = New-Object psobject -Property @{
                url    = "$($Uri)'$($item)'"
                method = "GET"
                id     = $batchid
            }
            $batchtable.requests += $deviceQuery
        }

   
    $body = $batchtable | ConvertTo-Json -Depth 10
    $results = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/`$batch" -Method POST  -Body $Body -ErrorAction Stop
    return $results.responses  

 

}

#requires -Module Microsoft.Graph.Authentication



$memberstoAdd = @{

    'members@odata.bind' = @(       
    )
}
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "GroupMember.ReadWrite.All", "Device.ReadWrite.All" -TenantId d65b7371-c385-4060-8b4c-b6510616cb67 -ErrorAction Stop

$serialNumbers = @(
    "4695-2922-8223-2994-0647-5227-72",
    "0815-3269-3311-2519-6027-6178-41"
)

$batchSize = 20

for ($i = 0; $i -lt $serialNumbers.Count; $i += $batchSize) {
       
    $currentBatch = $serialNumbers[$i..($i + $batchSize - 1)]
    $deviceIdParameters = @{
        Uri = "/deviceManagement/managedDevices?`$select=azureADDeviceId&`$filter=operatingSystem eq 'Windows' and serialNumber eq "
        ItemsArray = $currentBatch
        ErrorAction = "Stop"
    }
     $deviceIds = (Invoke-BatchRequest @deviceIdParameters).body.value.azureADDeviceId
     $entraIdParameters = @{
        Uri = "/devices?`$select=id&`$filter=deviceId eq "
        ItemsArray = $deviceIds
        ErrorAction = "Stop"
     }
     Invoke-BatchRequest @entraIdParameters | ForEach-Object {
        $memberstoAdd.'members@odata.bind' += "https://graph.microsoft.com/v1.0/directoryObjects/$($_.body.value.id)"
      }
     $addToGroupBody = $memberstoAdd | ConvertTo-Json
     Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/groups/e0830be6-5ee8-409f-accd-9d75ea6e69b9" -Body $addToGroupBody -ErrorAction Stop -OutputType PSObject
}
        
    

    
    



    
 
#$memberstoAdd.'members@odata.bind' += "https://graph.microsoft.com/v1.0/directoryObjects/$($_)"


#
