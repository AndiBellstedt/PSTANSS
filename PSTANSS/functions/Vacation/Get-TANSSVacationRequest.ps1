﻿function Get-TANSSVacationRequest {
    <#
    .Synopsis
        Get-TANSSVacationRequest

    .DESCRIPTION
        Query vacation requests of any state from TANSS

        By default the current year is queried

    .PARAMETER Id
        The explicit ID of the vacation request to get from TANSS

    .PARAMETER Year
        The year to list vacation requests for

    .PARAMETER Month
        The month of the year to list vacation requests

    .PARAMETER EmployeeId
        The Id of the employee to list vacation requests from

    .PARAMETER EmployeeName
        The name of the employee to list vacation requests from

    .PARAMETER DepartmentId
        Department Id filter

    .PARAMETER DepartmentName
        Department name filter

    .PARAMETER Type
        Name of the request type
        Values can be tabcompleted, so you don't have to type

        Available: "Urlaub", "Krankheit", "Abwesenheit", "Bereitschaft", "Überstunden abfeiern", "VACATION", "ILLNESS", "ABSENCE", "STAND_BY", "OVERTIME"

    .PARAMETER AbsenceSubTypeId
        For type "Abwesenheit", "ABSENCE" there are subtypes available.
        This one specifies the Id of the subtype to use

    .PARAMETER AbsenceSubTypeName
        For type "Abwesenheit", "ABSENCE" there are subtypes available.
        This one specifies the name of the subtype to use

        Values can be tabcompleted, so you don't have to type

    .PARAMETER ExcludeVacationRequestId
        Exclude filter on specific IDs

    .PARAMETER State
        The status for requests to list.

        Available values: "NEW", "REQUESTED", "APPROVED", "DECLINED"

    .PARAMETER CheckPermission
        Boolean value from the api wether to check permission or not

    .PARAMETER AddFrontendValue
        Boolean value to add request object on

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSVacationRequest

        Get all requests from the current year

    .EXAMPLE
        PS C:\> Get-TANSSVacationRequest -Year ((Get-Date).Year - 1)

        Get all requests from last year

    .EXAMPLE
        PS C:\> Get-TANSSVacationRequest -Type ILLNESS

        Get all illness records from the current year

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ListUserFriendly",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    [OutputType([TANSS.Vacation.Request])]
    Param(
        [Parameter(
            ParameterSetName = "Id",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [int[]]
        $Id,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [int]
        $Year = (Get-Date).Year,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [int]
        $Month,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [int[]]
        $EmployeeId,

        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [int[]]
        $EmployeeName,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [int[]]
        $DepartmentId,

        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [int[]]
        $DepartmentName,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [string[]]
        $Type,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [int[]]
        $AbsenceSubTypeId,

        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [string[]]
        $AbsenceSubTypeName,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [int[]]
        $ExcludeVacationRequestId,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [ValidateSet("NEW", "REQUESTED", "APPROVED", "DECLINED")]
        [string[]]
        $State,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [bool]
        $CheckPermission = $true,

        [Parameter( ParameterSetName = "ListApiNativ" )]
        [Parameter( ParameterSetName = "ListUserFriendly" )]
        [bool]
        $AddFrontendValue = $false,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning

    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        switch ($parameterSetName) {
            { $_ -like "Id" } {

                foreach ($requesterId in $Id) {
                    Write-PSFMessage -Level Verbose -Message "Query VacationRequestId $($requesterId)" -Tag "VacationRequest"

                    # Query VacationRequest by ID
                    $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/$($requesterId)"
                    $response = Invoke-TANSSRequest -Type "GET" -ApiPath $apiPath -Token $Token -WhatIf:$false

                    # Output result
                    Write-PSFMessage -Level Verbose -Message "$($response.meta.text): VacationRequestId $($requesterId)" -Tag "VacationRequest"
                    [TANSS.Vacation.Request]@{
                        BaseObject = $response.content
                        Id         = $response.content.id
                    }
                }

            }

            { $_ -like "List*" } {
                $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/list"

                #region parameter validation
                # Parameter EmployeeName
                if ($EmployeeName) {
                    Write-PSFMessage -Level Verbose -Message "Processing lookup on filtering for Employee '$( [string]::Join("'; '", [array]$EmployeeName) )'"

                    $EmployeeId = foreach ($item in $EmployeeName) {
                        $result = ConvertFrom-NameCache -Name $item -Type Employees -Verbose:$false
                        if (-not $result) {
                            Stop-PSFFunction -Message "Employee '$($item)' not found. Unable to query VacationRequests." -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "VacationAbsenceSubTypes", "CacheException"
                        } else {
                            $result
                        }
                    }

                    Write-PSFMessage -Level System -Message "Filtering on EmployeeId '$( [string]::Join("', '", [array]$EmployeeId) )'"
                }


                # Parameter DepartmentName
                if ($DepartmentName) {
                    Write-PSFMessage -Level Verbose -Message "Processing lookup on filtering for Department '$( [string]::Join("'; '", [array]$DepartmentName) )'"

                    $DepartmentId = foreach ($item in $DepartmentName) {
                        $result = ConvertFrom-NameCache -Name $item -Type Departments -Verbose:$false
                        if (-not $result) {
                            Stop-PSFFunction -Message "Department '$($item)' not found. Unable to query VacationRequests." -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "VacationAbsenceSubTypes", "CacheException"
                        } else {
                            $result
                        }
                    }

                    Write-PSFMessage -Level System -Message "Filtering on DepartmentId '$( [string]::Join("', '", [array]$DepartmentId) )'"
                }


                # Parameter Type
                if ($Type) {
                    Write-PSFMessage -Level System -Message "Processing filtering on Type '$( [string]::Join("', '", [array]$Type) )'"

                    $planningType = @()
                    foreach ($absenceType in $Type) {
                        switch ($absenceType) {
                            { $_ -like "Urlaub" } { $planningType += "VACATION" }
                            { $_ -like "Krankheit" } { $planningType += "ILLNESS" }
                            { $_ -like "Abwesenheit*" } { $planningType += "ABSENCE" }
                            { $_ -like "Bereitschaft" } { $planningType += "STAND_BY" }
                            { $_ -like "Überstunden abfeiern" } { $planningType += "OVERTIME" }
                            { $_ -in ("VACATION", "ILLNESS", "ABSENCE", "STAND_BY", "OVERTIME") } { $planningType += $_ }
                            default {
                                Stop-PSFFunction -Message "Unhandled Type '$($absenceType)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "VacationType", "SwitchException"
                            }
                        }
                    }
                    $planningType = $planningType | Sort-Object -Unique
                    Write-PSFMessage -Level Verbose -Message "Filtering on VacationRequestType '$( [string]::Join("', '", [array]$planningType) )'"
                }


                # Parameter AbsenceSubType
                if ($AbsenceSubTypeName) {
                    Write-PSFMessage -Level Verbose -Message "Processing lookup on filtering for AbsenceSubType '$( [string]::Join("', '", [array]$AbsenceSubTypeName) )'"

                    $AbsenceSubTypeId = foreach ($item in $AbsenceSubTypeName) {
                        $result = ConvertFrom-NameCache -Name $item -Type VacationAbsenceSubTypes -Verbose:$false
                        if (-not $result) {
                            Stop-PSFFunction -Message "AbsenceSubType '$($item)' not found. Unable to query VacationRequests." -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "VacationAbsenceSubTypes", "CacheException"
                        } else {
                            $result
                        }
                    }

                    Write-PSFMessage -Level System -Message "Filtering on AbsenceSubTypeId '$( [string]::Join("', '", [array]$AbsenceSubTypeId) )'"
                }
                #endregion parameter validation

                # Prepare body
                $body = @{}
                if ($Year) { $body.Add("year", $Year) }
                if ($Month) { $body.Add("month", $Month) }
                if ($EmployeeId) { $body.Add("employeeIds", [array]($EmployeeId)) }
                if ($DepartmentId) { $body.Add("departmentIds", [array]($DepartmentId)) }
                if ($planningType) { $body.Add("planningTypes", [array]($planningType)) }
                if ($AbsenceSubTypeId) { $body.Add("planningAdditionalIds", [array]($AbsenceSubTypeId)) }
                if ($ExcludeVacationRequestId) { $body.Add("excludeVacationRequestIds", [array]($ExcludeVacationRequestId)) }
                if ($State) { $body.Add("statesOnly", [array]($State)) }
                if ($CheckPermission) { $body.Add("checkPermissions", $CheckPermission) }
                if ($AddFrontendValue) { $body.Add("addFrontendValues", $AddFrontendValue) }
                Write-PSFMessage -Level Debug -Message "Prepared body for API request with parameters: '$( [string]::Join("', '", [array]($body.Keys)) )'" -Data $body -Tag "VacationRequest", "Query"

                $response = Invoke-TANSSRequest -Type "PUT" -ApiPath $apiPath -Body $body -Token $Token -WhatIf:$false
                Write-PSFMessage -Level Verbose -Message "Found $( ([array]($response.content.vacationRequests)).count ) request" -Tag "VacationRequest", "Output"
                Push-DataToCacheRunspace -MetaData $response.meta

                foreach ($vacationRequest in $response.content.vacationRequests) {
                    Write-PSFMessage -Level Debug -Message "Generating '$($vacationRequest.planningType)' request Id:$($vacationRequest.Id) with status '$($vacationRequest.status)" -Tag "VacationRequest", "Output"
                    [TANSS.Vacation.Request]@{
                        BaseObject = $vacationRequest
                        Id         = $vacationRequest.id
                    }
                }
            }

            Default {
                Stop-PSFFunction -Message "Unhandled ParameterSet '$($parameterSetName)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "SwitchException", "ParameterSet"
            }
        }


    }

    end {}
}
