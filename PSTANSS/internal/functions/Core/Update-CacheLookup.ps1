function Update-CacheLookup {
    <#
    .Synopsis
        Update-CacheLookup

    .DESCRIPTION
        Update a cache lookup hashtable with an object

    .PARAMETER LookupName
        Name of LokkupClass where to update

    .PARAMETER Id
        The Id to of the record to cache

    .PARAMETER Name
        The name of the record to cache

    .EXAMPLE
        PS C:\> Update-CacheLookup -LookupName "Departments" -Id $department.Id -Name $department.Name

        Update or insert the key from variable $department.Id of the cache-lookup-hashtable [TANSS.Lookup]::Departments with the name $department.Name

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding(
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [string]
        $LookupName,

        [int]
        $Id,

        [string]
        $Name
    )

    if ([TANSS.Lookup]::$LookupName["$($Id)"] -notlike $Name) {
        if ([TANSS.Lookup]::$LookupName["$($Id)"]) {
            Write-PSFMessage -Level Debug -Message "Update existing id '$($Id)' in [TANSS.Lookup]::$($LookupName) with value '$($Name)'" -Tag "Cache", $LookupName
            [TANSS.Lookup]::$LookupName["$($Id)"] = $Name
        } else {
            Write-PSFMessage -Level Debug -Message "Insert in [TANSS.Lookup]::$($LookupName): $($Id) - '$($($Name))'" -Tag "Cache", $LookupName
            ([TANSS.Lookup]::$LookupName).Add("$($Id)", $Name)
        }
    }

}
