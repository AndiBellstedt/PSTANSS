function Set-TANSSVacationEntitlement {
    <#
    .Synopsis
        Set-TANSSVacationEntitlement

    .DESCRIPTION
        Description

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .PARAMETER PassThru
        Outputs the result to the console

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Set-VacationEntitlement -Year 2022 -EmployeeId 2 -Days 30

        Set entitlement for employee ID 2 to 30 days in year 2022

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ByInputObject",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [TANSS.Vacation.Entitlement[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ById",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [int[]]
        $EmployeeId,

        [Parameter(
            ParameterSetName = "ByName",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]
        $EmployeeName,

        [ValidateNotNullOrEmpty()]
        [int]
        $Year = (Get-Date).Year,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("NumberOfDays")]
        [int]
        $Days,

        [ValidateNotNullOrEmpty()]
        [Alias("DaysTransfered")]
        [int]
        $TransferedDays,

        [switch]
        $PassThru,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        #ToDo - Query Id from EmployeeName

        #ToDo - Query Entitlement from EmployeeId

        foreach ($entitlement in $InputObject) {
            if ($pscmdlet.ShouldProcess("Vacation entitlement for '$($entitlement.EmployeeName)' to $($Days) days in $($Year)", "Set")) {
                # Prepare request
                $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/vacationDays"
                if ($TransferedDays) { $_transferred = $TransferedDays } else { $_transferred = 0 }
                $body = @{
                    "employeeId"   = $entitlement.employeeId
                    "year"         = $entitlement.year
                    "numberOfDays" = $Days
                    "transferred"  = $_transferred
                }

                # Set entitlement
                $response = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $body -Token $Token

                # Output result
                if ($PassThru) {
                    #Write-PSFMessage -Level Verbose -Message "$($response.meta.text): Received $($response.meta.properties.extras.count) VacationEntitlement records in year $($Year)" -Tag "VacationEntitlement", "Query"
                    foreach ($newEntitlement in $response.content) {
                        $_baseObject = $entitlement.BaseObject
                        $_baseObject.numberOfDays = $newEntitlement.numberOfDays
                        if ($newEntitlement.transferred) {
                            $_transferred = $newEntitlement.transferred
                            $_baseObject.TransferedDays = $_transferred
                        } else {
                            $_transferred = 0
                        }

                        [TANSS.Vacation.Entitlement]@{
                            BaseObject     = $_baseObject
                            EmployeeId     = $newEntitlement.employeeId
                            Year           = $newEntitlement.year
                            NumberOfDays   = $newEntitlement.numberOfDays
                            TransferedDays = $_transferred
                        }
                    }
                }
            }
        }
    }

    end {}
}
