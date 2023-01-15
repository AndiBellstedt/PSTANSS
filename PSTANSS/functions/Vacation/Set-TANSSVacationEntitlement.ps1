function Set-TANSSVacationEntitlement {
    <#
    .Synopsis
        Set-TANSSVacationEntitlement

    .DESCRIPTION
        Description

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

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
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "VacationEntitlement", "Set"

        if ($parameterSetName -notlike "ByInputObject") {
            $tempWhatIf = $WhatIfPreference
            $WhatIfPreference = $false
            $InputObject = Get-TANSSVacationEntitlement -Year $Year -Token $Token
            $WhatIfPreference = $tempWhatIf
        }

        # Filter on EmployeeName
        if ($parameterSetName -like "ByName") {
            $InputObject = foreach ($_employeeName in $EmployeeName) {
                $InputObject | Where-Object EmployeeName -like $_employeeName
            }
            Write-PSFMessage -Level Verbose -Message "Select $(([array]$InputObject).Count) records, by employee name '$([string]::Join("', '", ([array]$EmployeeName)))'" -Tag "VacationEntitlement", "Set", "Filtering"
        }

        # Filter on EmployeeId
        if ($parameterSetName -like "ById") {
            $InputObject = foreach ($_employeeId in $EmployeeId) {
                $InputObject | Where-Object EmployeeId -like $_employeeId
            }
            Write-PSFMessage -Level Verbose -Message "Select $(([array]$InputObject).Count) records, by employee id '$([string]::Join("', '", ([array]$EmployeeId)))'" -Tag "VacationEntitlement", "Set", "Filtering"
        }

        # Process VacationEntitlement modification
        foreach ($entitlement in $InputObject) {
            if ($pscmdlet.ShouldProcess("Vacation entitlement for '$($entitlement.EmployeeName)' to $($Days) days in $($Year)", "Set")) {
                Write-PSFMessage -Level Verbose -Message "Set vacation entitlement for '$($entitlement.EmployeeName)' to $($Days) days in $($Year)" -Tag "VacationEntitlement", "Set"

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
                    Write-PSFMessage -Level Verbose -Message "$($response.meta.text): Going to output $(([array]($response.content)).count) VacationEntitlement records in year $($Year)" -Tag "VacationEntitlement", "Query"
                    foreach ($newEntitlement in $response.content) {
                        $_baseObject = $entitlement.BaseObject
                        $_baseObject.numberOfDays = $newEntitlement.numberOfDays
                        if ($newEntitlement.transferred) {
                            $_transferred = $newEntitlement.transferred
                            if($_baseObject.TransferedDays) { $_baseObject.TransferedDays = $_transferred }
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
