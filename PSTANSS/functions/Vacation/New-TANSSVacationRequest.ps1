﻿function New-TANSSVacationRequest {
    <#
    .Synopsis
        New-TANSSVacationRequest

    .DESCRIPTION
        Create a new vacation/absence request within TANSS for a specified employee on a date period
        There are various types of "absence":
            - Vacation
            - Illness
            - Absence
            - Standby
            - Overtime
        The command is called with a paramiter called like the absence type to request

        The type "Absence" can have a subset of additional types. They can be specified by name (Tabcompletion is available),
        or by a TANSS.Vacation.AbsenceSubType object. The additional absence types can be queried by the command "Get-TANSSVacationAbsenceSubType"

    .PARAMETER Vacation
        Switch parameter to command the creation of a vacation request

    .PARAMETER Illness
        Switch parameter to command the creation of a Illness record

    .PARAMETER Absence
        Switch parameter to command the creation of a absence record

    .PARAMETER AbsenceSubType
        TANSS.Vacation.AbsenceSubType object to specify what kind of absence subtype to create

    .PARAMETER AbsenceSubTypeName
        The name of the absence subtype to create

    .PARAMETER Standby
        Switch parameter to command the creation of a Standby record

    .PARAMETER Overtime
        Switch parameter to command the creation of a Overtime record

    .PARAMETER EmployeeId
        The ID of the employee to create to request/record for

    .PARAMETER StartDate
        The start date

    .PARAMETER EndDate
        The end date

    .PARAMETER HalfDayStart
        Boolean to specify if the first day is created as a half day (forenoon not in the absence)

    .PARAMETER HalfDayEnd
        Boolean to specify if the last day is created as a half day (afternoon not in the absence)

    .PARAMETER Description
        Optional description for the request/record

    .PARAMETER Date
        The creation of the request/record
        By default this is the current date.

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> New-TANSSVacationRequest -Illness -EmployeeId 10 -Start "01/02/2023" -End "01/03/2023"

        Creates an illness record for employee with ID 10 for second of january 2023 to third of january 2023

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding(
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([TANSS.Vacation.Request])]
    Param(
        [Parameter(ParameterSetName = "Vacation", Mandatory = $true)]
        [switch]
        $Vacation,

        [Parameter(ParameterSetName = "Illness", Mandatory = $true)]
        [switch]
        $Illness,

        [Parameter(ParameterSetName = "Absence", Mandatory = $true)]
        [Parameter(ParameterSetName = "AbsenceWithAbsenceObject", Mandatory = $true)]
        [Parameter(ParameterSetName = "AbsenceWithAbsenceName", Mandatory = $true)]
        [switch]
        $Absence,

        [Parameter(ParameterSetName = "AbsenceWithAbsenceObject", Mandatory = $true)]
        [TANSS.Vacation.AbsenceSubType]
        $AbsenceSubType,

        [Parameter(ParameterSetName = "AbsenceWithAbsenceName", Mandatory = $true)]
        [string]
        $AbsenceSubTypeName,

        [Parameter(ParameterSetName = "Standby", Mandatory = $true)]
        [switch]
        $Standby,

        [Parameter(ParameterSetName = "Overtime", Mandatory = $true)]
        [switch]
        $Overtime,

        [int[]]
        $EmployeeId,

        [Parameter(Mandatory = $true)]
        [datetime]
        $StartDate,

        [Parameter(Mandatory = $true)]
        [datetime]
        $EndDate,

        [Alias("StartHalfDay")]
        [bool]
        $HalfDayStart = $false,

        [Alias("EndHalfDay")]
        [bool]
        $HalfDayEnd = $false,

        [Alias("Reason", "RequestReason")]
        [string]
        $Description,

        [Alias("RequestDate")]
        [datetime]
        $Date = (Get-Date),

        [TANSS.Connection]
        $Token
    )

    begin {
        # Validation - Basic checks
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "VacationRequest"

        #region Validation
        # Check dates
        if ($StartDate -gt $EndDate) {
            Stop-PSFFunction -Message "Specified dates are not valid! Please check dates, StartDate '$($StartDate)' is greater then EndDate '$($EndDate))'" -EnableException $true -Cmdlet $pscmdlet
        }

        # Fallback to employeeId from token if no requestorId is set
        if (-not $EmployeeId) {
            Write-PSFMessage -Level Verbose -Message "No Employee specified, using current logged in employee '$($Token.UserName)' (Id:$($Token.EmployeeId))" -Tag "VacationRequest", "EmployeeId"
            $EmployeeId = $Token.EmployeeId
        }

        # Find additional AbsenceSubType from specified name
        if ($parameterSetName -like "AbsenceWithAbsenceName") {
            Write-PSFMessage -Level System -Message "Gathering TANSS absence type '$($AbsenceSubTypeName)'" -Tag "VacationRequest", "AbsenceSubType", "Lookup"

            $tmpWhatIfPreference = $WhatIfPreference
            $WhatIfPreference = $fals
            $AbsenceSubType = Get-TANSSVacationAbsenceSubType -Name $AbsenceSubTypeName -Token $Token -ErrorAction Ignore
            $WhatIfPreference = $tmpWhatIfPreference
            Remove-Variable tmpWhatIfPreference -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false

            if ($AbsenceSubType) {
                Write-PSFMessage -Level Verbose -Message "Found AbsenceSubTypeId '$($AbsenceSubType.Id)' for '$($AbsenceSubTypeName)'"
            } else {
                Stop-PSFFunction -Message "Unable to find AbsenceSubType '$($AbsenceSubTypeName)'" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "AbsenceSubType"
            }
        }

        # set planningType
        switch ($parameterSetName) {
            { $_ -like "Vacation" } { $planningType = "VACATION" }
            { $_ -like "Illness" } { $planningType = "ILLNESS" }
            { $_ -like "Absence*" } { $planningType = "ABSENCE" }
            { $_ -like "Standby" } { $planningType = "STAND_BY" }
            { $_ -like "Overtime" } { $planningType = "OVERTIME" }
            Default {
                Stop-PSFFunction -Message "Unhandled ParameterSetName. Unable to set planningType for VacationRequest. Developers mistake!" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "PlanningType"
            }
        }
        #endregion Validation - checking parameters


        foreach ($requesterId in $EmployeeId) {
            $_requestDate = [int][double]::Parse((Get-Date -Date $Date.ToUniversalTime() -UFormat %s))

            # gathering absence object
            $plannedVactionRequest = Request-TANSSVacationRequestObject -EmployeeId $requesterId -Type $planningType -StartDate $StartDate -EndDate $EndDate -Token $Token
            if(-not $plannedVactionRequest) { continue }

            Write-PSFMessage -Level Verbose -Message "Adding RequestDate and optional description to VacationRequest object" -Tag "VacationRequest", "VactionRequestObject"
            $plannedVactionRequest.BaseObject.requestReason = "$($Description)"
            $plannedVactionRequest.BaseObject.requestDate = $_requestDate
            if ($AbsenceSubType) {
                Write-PSFMessage -Level Verbose -Message "Insert additionalAbsenceSubType '$($AbsenceSubType.Name)' to VacationRequest object" -Tag "VacationRequest", "VactionRequestObject", "AbsenceSubType"
                $plannedVactionRequest.BaseObject.planningAdditionalId = $AbsenceSubType.Id
            }

            $days = $plannedVactionRequest.Days
            if($HalfDayStart) { $days[0].Afternoon = $false }
            if($HalfDayEnd) { $days[-1].Forenoon = $false }
            $plannedVactionRequest.Days = $days
            Remove-Variable -Name days -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore

            $body = $plannedVactionRequest.BaseObject | ConvertTo-PSFHashtable
            # enforce types, due to some strange conversation behaviour sometimes
            $body.days = [array]$body.days
            $body.startDate = [int]$body.startDate
            $body.endDate = [int]$body.endDate

            $apiPath = Format-ApiPath -Path "api/v1/vacationRequests"

            $daycount = 0 + ($plannedVactionRequest.days | Measure-Object | Select-Object -ExpandProperty Count)
            if ($pscmdlet.ShouldProcess("VacationRequest for employeeId '$($RequesterId)' with $($daycount) days on planningType '$($planningType)' on dates '$(Get-Date -Date $StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $EndDate -Format 'yyyy-MM-dd')'", "Add")) {
                Write-PSFMessage -Level Verbose -Message "Add VacationRequest for employeeId '$($RequesterId)' with $($daycount) days on planningType '$($planningType)' on dates '$(Get-Date -Date $StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $EndDate -Format 'yyyy-MM-dd')'" -Tag "VacationRequest", "VactionRequestObject"

                # Create the object within TANSS
                $result = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body -Token $Token -WhatIf:$false
                Write-PSFMessage -Level Verbose -Message "$($result.meta.text) - RequestId '$($result.content.id)' with status '$($result.content.status)'" -Tag "VacationRequest", "VactionRequestObject", "VacationRequestResult"

                # output the result
                [TANSS.Vacation.Request]@{
                    BaseObject = $result.content
                    Id         = $result.content.id
                }
            }
        }
    }

    end {
    }
}
