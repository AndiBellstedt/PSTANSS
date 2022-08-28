function ConvertFrom-NameCache {
    <#
    .Synopsis
       ConvertFrom-NameCache

    .DESCRIPTION
       Convert Name to ID from cached TANSS.Lookup values

    .PARAMETER Name
        Name to convert into ID

    .PARAMETER Id
        Id to convert into Name

    .PARAMETER Type
        Lookup type where the name should convert from

    .EXAMPLE
       ConvertFrom-NameCache -Name "User X" -Type "Employee"

       Example

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt
    #>
    [CmdletBinding(
        DefaultParameterSetName="FromName",
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            ParameterSetName="FromName",
            Mandatory=$true
        )]
        [string]
        $Name,

        [Parameter(
            ParameterSetName="FromId",
            Mandatory=$true
        )]
        [int]
        $Id,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Companies","Contracts","CostCenters","Departments","Employees","OrderBys","Phases","Tags","Tickets","TicketStates","TicketTypes")]
        [string]
        $Type

    )

    $parameterSetName = $pscmdlet.ParameterSetName
    Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

    switch ($parameterSetName) {
        "FromName" {
            Write-PSFMessage -Level Verbose -Message "Start converting '$($Name)' of type '$($Type)' to ID"
            if( ([TANSS.Lookup]::$Type).ContainsValue($Name) ) {
                foreach($key in [TANSS.Lookup]::$Type.Keys) {
                    if([TANSS.Lookup]::$Type[$key] -like $Name) {
                        Write-PSFMessage -Level Verbose -Message "Found ID '$key' for name '$($Name)' of type '$($Type)'"
                        return $key
                    }
                }
            } else {
                Write-PSFMessage -Level Error -Message "Unable to convert '$($Name)' of type '$($Type)' in ID. Name is not in present in cache and TANSS API can't be queried directly for $($Type)"
            }
        }

        "FromId" {
            Write-PSFMessage -Level Verbose -Message "Start converting ID '$($Id)' of type '$($Type)' to name"
            if( ([TANSS.Lookup]::$Type).ContainsKey("$($Id)") ) {
                $output = [TANSS.Lookup]::$Type["$($Id)"]
                Write-PSFMessage -Level Verbose -Message "Found '$output' with ID '$($Id)' of type '$($Type)'"
                return $output
            } else {
                Write-PSFMessage -Level Error -Message "Unable to convert '$($Id)' of type '$($Type)' into Name. Id is not in present in cache and TANSS API can't be queried directly for $($Type)"
            }
        }

        Default {
            Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true
            throw
         }
    }

}
