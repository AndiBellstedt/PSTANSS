function Get-TANSSVacationEntitlement {
    <#
    .Synopsis
        Get-VacationEntitlement

    .DESCRIPTION
        Description

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-VacationEntitlement -Year 2022

        Query entitlement from all employees in year 2022

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [ValidateNotNullOrEmpty()]
        [int]
        $Year = (Get-Date).Year,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        # Query entitlement for year
        $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/vacationDays/year/$($Year)"
        $response = Invoke-TANSSRequest -Type "GET" -ApiPath $apiPath -Token $Token

        # Output result
        Write-PSFMessage -Level Verbose -Message "$($response.meta.text): Received $($response.meta.properties.extras.count) VacationEntitlement records in year $($Year)" -Tag "VacationEntitlement", "Query"
        foreach ($entitlement in $response.content) {
            $_transferred = if ($entitlement.transferred) { $entitlement.transferred } else { 0 }
            [TANSS.Vacation.Entitlement]@{
                BaseObject     = $entitlement
                EmployeeId     = $entitlement.employeeId
                Year           = $entitlement.year
                NumberOfDays   = $entitlement.numberOfDays
                TransferedDays = $_transferred
            }
        }
    }

    end {}
}
