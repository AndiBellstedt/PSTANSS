# start infinite loop, until "control boolean" [TANSS.Cache]::StopValidationRunspace is set to true
do {

    if ([TANSS.Cache]::Data.Keys.count -gt 0) {
        Write-PSFMessage -Level SomewhatVerbose -Message "Working on $([TANSS.Cache]::Data.Keys.count) record$(if([TANSS.Cache]::Data.Keys.count -gt 1) {'s'}) in TANSS.Cache data object" -FunctionName "Expand-TANSSCacheData" -Tag "Cache"

        foreach ($key in [TANSS.Cache]::Data.Keys) {

            foreach ($name in [TANSS.Cache]::Data[$key].linkedEntities.psobject.Properties.Name) {
                $lookupObject = [TANSS.Cache]::Data[$key].linkedEntities.$name

                foreach ($id in $lookupObject.psobject.Properties.Name) {
                    if ([TANSS.Lookup]::$name[$id] -notlike $lookupObject.$id.name) {
                        if ([TANSS.Lookup]::$name[$id]) {
                            Write-PSFMessage -Level Debug -Message "Update existing id '$($id)' in [TANSS.Lookup]::$($name) with value '$($lookupObject.$id.name)'" -FunctionName "Expand-TANSSCacheData" -Tag "Cache"
                            [TANSS.Lookup]::$name[$id] = $lookupObject.$id.name
                        } else {
                            Write-PSFMessage -Level Debug -Message "Insert in [TANSS.Lookup]::$($name): $($id) - '$($($lookupObject.$id.name))'" -FunctionName "Expand-TANSSCacheData" -Tag "Cache"
                            ([TANSS.Lookup]::$name).Add($id, $lookupObject.$id.name)
                        }
                    }
                }
            }

            [TANSS.Cache]::Data.Remove($key)
        }
    }

    Start-Sleep -Milliseconds 250

} until ([TANSS.Cache]::StopValidationRunspace -eq $true)
