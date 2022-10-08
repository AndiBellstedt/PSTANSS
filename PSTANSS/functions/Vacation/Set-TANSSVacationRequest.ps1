function Set-TANSSVacationRequest {
    <#
    .Synopsis
        Set-TANSSVacationRequest

    .DESCRIPTION
        Modfiy a vacation/absence record within TANSS

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .PARAMETER PassThru
        Outputs the result to the console

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        Verb-Noun

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ByInputObjectWithSubType",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = "ByInputObjectWithSubTypeName",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [TANSS.Vacation.Request[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ByIdWithSubType",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = "ByIdWithSubTypeName",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias("RequestId", "VacationRequestId")]
        [int[]]
        $Id,

        [ValidateNotNullOrEmpty()]
        [string]
        $Type,

        [Parameter(ParameterSetName = "ByInputObjectWithSubType")]
        [Parameter(ParameterSetName = "ByIdWithSubType")]
        [ValidateNotNullOrEmpty()]
        [TANSS.Vacation.AbsenceSubType]
        $AbsenceSubType,

        [Parameter(ParameterSetName = "ByInputObjectWithSubTypeName")]
        [Parameter(ParameterSetName = "ByIdWithSubTypeName")]
        [ValidateNotNullOrEmpty()]
        [string]
        $AbsenceSubTypeName,

        [ValidateNotNullOrEmpty()]
        [datetime]
        $StartDate,

        [ValidateNotNullOrEmpty()]
        [datetime]
        $EndDate,

        [Alias("Reason", "RequestReason")]
        [string]
        $Description,

        [ValidateNotNullOrEmpty()]
        [Alias("RequestDate")]
        [datetime]
        $Date,

        [switch]
        $PassThru,

        [TANSS.Connection]
        $Token
    )

    begin {
        # Validation - Basic checks
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning

        # Parameter Type
        if ($Type) {
            Write-PSFMessage -Level System -Message "Processing Type '$($Type)'"

            switch ($Type) {
                { $_ -like "Urlaub" } { $planningType = "VACATION" }
                { $_ -like "Krankheit" } { $planningType = "ILLNESS" }
                { $_ -like "Abwesenheit*" } { $planningType = "ABSENCE" }
                { $_ -like "Bereitschaft" } { $planningType = "STAND_BY" }
                { $_ -like "Überstunden abfeiern" } { $planningType = "OVERTIME" }
                { $_ -in ("VACATION", "ILLNESS", "ABSENCE", "STAND_BY", "OVERTIME") } { $planningType = $_ }
                default {
                    Stop-PSFFunction -Message "Unhandled Type '$($Type)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "VacationType", "SwitchException"
                }
            }
            Write-PSFMessage -Level System -Message "Using VacationRequestType '$($planningType)'"
        }

        if(($AbsenceSubType -or $AbsenceSubTypeName) -and ($Type -like "ABSENCE")) {
            if($AbsenceSubTypeName) {
                $AbsenceSubType = Get-TANSSVacationAbsenceSubType -Name $AbsenceSubTypeName
            }
        } else {
            Write-PSFMessage -Level Important -Message "AbsenceSubType specified, but not valid for '$($Type)'! AbsenceSubTypes are only possible with Type 'Abwesenheit'/'ABSENCE'. Setting will be ignored" -Tag "VacationRequest", "AbsenceSubType"
            $AbsenceSubType = $null
            $AbsenceSubTypeName = $null
        }
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "VacationRequest"

        #region Validation
        # Check dates
        if (($StartDate -and $EndDate) -and ($StartDate -gt $EndDate)) {
            Stop-PSFFunction -Message "Specified dates are not valid! Please check dates, StartDate '$($StartDate)' is greater then EndDate '$($EndDate))'" -EnableException $true -Cmdlet $pscmdlet
        }

        # Find additional AbsenceSubType from specified name
        if ($parameterSetName -like "*WithSubTypeName") {
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

        #endregion Validation - checking parameters


        # If Id is piped in, query vacationRequests from TANSS
        if ($parameterSetName -like "ById*") {
            $InputObject = foreach ($requesterId in $Id) {
                Write-PSFMessage -Level Verbose -Message "Query VacationRequestId $($requesterId)" -Tag "VacationRequest", "Query"

                # Query VacationRequest by ID
                $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/$($requesterId)"
                $response = Invoke-TANSSRequest -Type "GET" -ApiPath $apiPath -Token $Token -Confirm:$false

                # Output result
                Write-PSFMessage -Level Verbose -Message "$($response.meta.text): VacationRequestId $($requesterId)" -Tag "VacationRequest", "Query"
                [TANSS.Vacation.Request]@{
                    BaseObject = $response.content
                    Id         = $response.content.id
                }
            }
        }



        foreach ($vacationRequest in $InputObject) {
            Write-PSFMessage -Level Verbose -Message "Working on '$($vacationRequest.TypeName)' VacationRequest '$($vacationRequest.Id)' ($($vacationRequest.EmployeeName)) for range '$($vacationRequest.StartDate) - $($vacationRequest.EndDate)'" -Tag "VacationRequest", "Set"

            # earlier Startdate should be set --> VacationDay objects have to be added to days property
            if ($StartDate -lt $vacationRequest.StartDate) {
                Write-PSFMessage -Level System -Message "StartDate found, need to add $(($vacationRequest.EndDate - $StartDate).Days) days to VacationRequest" -Tag "VacationRequest", "Set", "AddDays"

                # Set parameters to query addiontial days
                $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/properties"
                $_startDate = [int][double]::Parse((Get-Date -Date $StartDate.Date.ToUniversalTime() -UFormat %s))
                $body = @{
                    "requesterId"  = $vacationRequest.BaseObject.requesterId
                    "planningType" = $vacationRequest.BaseObject.planningType
                    "startDate"    = $_startDate
                    "endDate"      = $vacationRequest.BaseObject.endDate
                }

                # query planned vacation request object with additional days
                $plannedVactionRequest = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body -Token $Token -WhatIf:$false | Select-Object -ExpandProperty content
                if ($plannedVactionRequest) {
                    Write-PSFMessage -Level Verbose -Message "Received VacationRequest object with $($plannedVactionRequest.days | Measure-Object | Select-Object -ExpandProperty Count) days on planningType '$($planningType)'" -Tag "VacationRequest", "VactionRequestObject"
                } else {
                    Stop-PSFFunction -Message "Unable gathering '$($planningType)' VacationRequest object for employeeId '$($requesterId)' on dates '$(Get-Date -Date $StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $EndDate -Format 'yyyy-MM-dd')' from '$($Token.Server)'" -Cmdlet $pscmdlet
                    continue
                }
                $plannedVactionRequest = [TANSS.Vacation.Request]@{
                    BaseObject = $plannedVactionRequest
                    id = $plannedVactionRequest.id
                }

                # add days new days to vacation request
                $vacationRequest.Days = $plannedVactionRequest.Days
                Write-PSFMessage -Level System -Message "VacationRequest '$($vacationRequest.Id)' is modified with ne Startdate, new range '$($vacationRequest.StartDate) - $($vacationRequest.EndDate)'" -Tag "VacationRequest", "Set", "AddDays"

                Remove-Variable -Name apiPath, _startDate, body, plannedVactionRequest -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction:Ignore -WarningAction:Ignore -InformationAction:Ignore
            }

            # Later Enddate should be set --> VacationDay objects have to be added to days property
            if ($EndDate -gt $vacationRequest.EndDate) {
                Write-PSFMessage -Level System -Message "EndDate found, need to add $(($EndDate - $vacationRequest.EndDate).Days) days to VacationRequest" -Tag "VacationRequest", "Set", "AddDays"

                # Set parameters to query addiontial days
                $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/properties"
                $_endDate = [int][double]::Parse((Get-Date -Date $EndDate.Date.ToUniversalTime() -UFormat %s))
                $body = @{
                    "requesterId"  = $vacationRequest.BaseObject.requesterId
                    "planningType" = $vacationRequest.BaseObject.planningType
                    "startDate"    = $vacationRequest.BaseObject.startDate
                    "endDate"      = $_endDate
                }

                # query planned vacation request object with additional days
                $plannedVactionRequest = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body -Token $Token -WhatIf:$false | Select-Object -ExpandProperty content
                if ($plannedVactionRequest) {
                    Write-PSFMessage -Level Verbose -Message "Received VacationRequest object with $($plannedVactionRequest.days | Measure-Object | Select-Object -ExpandProperty Count) days on planningType '$($planningType)'" -Tag "VacationRequest", "VactionRequestObject"
                } else {
                    Stop-PSFFunction -Message "Unable gathering '$($planningType)' VacationRequest object for employeeId '$($requesterId)' on dates '$(Get-Date -Date $StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $EndDate -Format 'yyyy-MM-dd')' from '$($Token.Server)'" -Cmdlet $pscmdlet
                    continue
                }
                $plannedVactionRequest = [TANSS.Vacation.Request]@{
                    BaseObject = $plannedVactionRequest
                    id = $plannedVactionRequest.id
                }

                # add days new days to vacation request
                $vacationRequest.Days = $plannedVactionRequest.Days
                Write-PSFMessage -Level System -Message "VacationRequest '$($vacationRequest.Id)' is modified with ne Startdate, new range '$($vacationRequest.StartDate) - $($vacationRequest.EndDate)'" -Tag "VacationRequest", "Set", "AddDays"

                Remove-Variable -Name apiPath, _endDate, body, plannedVactionRequest -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction:Ignore -WarningAction:Ignore -InformationAction:Ignore
            }

            # Later StartDate should be set --> have to be remove days from VacationRequest objects
            if ($StartDate -and ($StartDate -ne $vacationRequest.StartDate)) {
                Write-PSFMessage -Level System -Message "StartDate found, need to remove $(($StartDate - $vacationRequest.StartDate).Days) day(s) from VacationRequest '$($vacationRequest.Id)'" -Tag "VacationRequest", "Set", "RemoveDays"

                $_startDate = [int][double]::Parse((Get-Date -Date $StartDate.Date.ToUniversalTime() -UFormat %s))
                $vacationRequest.BaseObject.startDate = $_startDate
                $vacationRequest.Days = $vacationRequest.Days | Where-Object date -ge $StartDate
            }

            # Earlier EndDate should be set --> have to be remove days from VacationRequest objects
            if ($EndDate -and ($EndDate -ne $vacationRequest.EndDate)) {
                Write-PSFMessage -Level System -Message "EndDate found, need to remove $(($EndDate - $vacationRequest.EndDate).Days * -1) day(s) from VacationRequest '$($vacationRequest.Id)'" -Tag "VacationRequest", "Set", "RemoveDays"

                $_endDate = [int][double]::Parse((Get-Date -Date $EndDate.Date.ToUniversalTime() -UFormat %s))
                $vacationRequest.BaseObject.endDate = $_endDate
                $vacationRequest.Days = $vacationRequest.Days | Where-Object date -le $EndDate
            }

            # Set date
            if ($Date) {
                Write-PSFMessage -Level System -Message "RequestDeate found, going to change Date from '$($vacationRequest.Date)' to '$($Date)'" -Tag "VacationRequest", "Set", "RequestDate"

                $_requestDate = [int][double]::Parse((Get-Date -Date $Date.ToUniversalTime() -UFormat %s))
                $vacationRequest.BaseObject.requestDate = $_requestDate
            }

            # Set Description
            if ($Description) {
                Write-PSFMessage -Level System -Message "Description found, going to change description from '$($vacationRequest.Description)' to '$($Description)'" -Tag "VacationRequest", "Set", "RequestDate"
                $vacationRequest.BaseObject.requestReason = "$($Description)"
            }

            # Set type
            if($planningType) {
                Write-PSFMessage -Level System -Message "Type found, going to change Type from '$($vacationRequest.Type)' to '$($planningType)'" -Tag "VacationRequest", "Set", "Type"
                $vacationRequest.BaseObject.planningType = $planningType

                # remove additional planning type when change from absence so something else
                if(($vacationRequest.BaseObject.planningType -notlike "ABSENCE") -and ($vacationRequest.BaseObject.planningAdditionalId -gt 0)) {
                    $vacationRequest.BaseObject.planningAdditionalId = 0
                }
            }

            # Set AbsenceSubType
            if ($AbsenceSubType) {
                Write-PSFMessage -Level Verbose -Message "Set additionalAbsenceSubType '$($AbsenceSubType.Name)' to VacationRequest object" -Tag "VacationRequest", "Set", "AbsenceSubType"
                $vacationRequest.BaseObject.planningAdditionalId = $AbsenceSubType.Id
            }

            # Make the change effective within TANSS
            $body = $vacationRequest.BaseObject | ConvertTo-PSFHashtable
            $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/$($vacationRequest.Id)"

            if ($pscmdlet.ShouldProcess("VacationRequest for employeeId '$($vacationRequest.EmployeeId)' with $($vacationRequest.days | Measure-Object | Select-Object -ExpandProperty Count) days on planningType '$($vacationRequest.Type)' on dates '$(Get-Date -Date $vacationRequest.StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $vacationRequest.EndDate -Format 'yyyy-MM-dd')'", "Set")) {
                Write-PSFMessage -Level Verbose -Message "Set VacationRequest for employeeId '$($vacationRequest.EmployeeId)' with $($vacationRequest.days | Measure-Object | Select-Object -ExpandProperty Count) days on planningType '$($vacationRequest.Type)' on dates '$(Get-Date -Date $vacationRequest.StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $vacationRequest.EndDate -Format 'yyyy-MM-dd')'" -Tag "VacationRequest", "Set"

                # Create the object within TANSS
                $result = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $body -Token $Token
                Write-PSFMessage -Level Verbose -Message "$($result.meta.text) - RequestId '$($result.content.id)' with status '$($result.content.status)'" -Tag "VacationRequest", "VactionRequestObject", "VacationRequestResult"

                # output the result
                if($result -and $PassThru) {
                    [TANSS.Vacation.Request]@{
                        BaseObject = $result.content
                        Id         = $result.content.id
                    }
                }
            }
        }
    }

    end {
    }
}
