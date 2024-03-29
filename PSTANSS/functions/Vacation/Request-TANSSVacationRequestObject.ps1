﻿function Request-TANSSVacationRequestObject {
    <#
    .Synopsis
        Request-TANSSVacationRequestObject

    .DESCRIPTION
        Retrieve a vacation request object from TANSS.
        This object can be used to create a new VacationRequest

    .PARAMETER EmployeeId
        The ID of the employee to request for

    .PARAMETER EmployeeName
        The name of the employee to request for

    .PARAMETER StartDate
        The start date

    .PARAMETER EndDate
        The end date

    .PARAMETER Type
        Name of the request type
        Values can be tabcompleted, so you don't have to type

        Available: "Urlaub", "Krankheit", "Abwesenheit", "Bereitschaft", "Überstunden abfeiern", "VACATION", "ILLNESS", "ABSENCE", "STAND_BY", "OVERTIME"

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Request-TANSSVacationRequestObject -EmployeeId 10 -Type "Urlaub" -Start "01/02/2023" -End "01/03/2023"

        Request a object to create a new vacation request in the database for employee with ID 10. The output will be of type and from 2.1.2023 to 03.01.2023

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ApiNative",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    [OutputType([TANSS.Vacation.Request])]
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            ParameterSetName = "ApiNative"
        )]
        [int[]]
        $EmployeeId,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            ParameterSetName = "UserFriendly",
            Mandatory = $true
        )]
        [string[]]
        $EmployeeName,

        [Parameter(Mandatory = $true)]
        [string]
        $Type,

        [Parameter(Mandatory = $true)]
        [datetime]
        $StartDate,

        [Parameter(Mandatory = $true)]
        [datetime]
        $EndDate,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning

        # Parameter Type
        if ($Type) {
            Write-PSFMessage -Level System -Message "Processing Type '$($Type)'" -Tag "VacationRequest", "Request", "VacationType"

            switch ($Type) {
                { $_ -like "Urlaub" } { $planningType = "VACATION" }
                { $_ -like "Krankheit" } { $planningType = "ILLNESS" }
                { $_ -like "Abwesenheit*" } { $planningType = "ABSENCE" }
                { $_ -like "Bereitschaft" } { $planningType = "STAND_BY" }
                { $_ -like "Überstunden abfeiern" } { $planningType = "OVERTIME" }
                { $_ -in ("VACATION", "ILLNESS", "ABSENCE", "STAND_BY", "OVERTIME") } { $planningType = $_ }
                default {
                    Stop-PSFFunction -Message "Unhandled Type '$($Type)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "Request", "VacationType", "SwitchException"
                }
            }
            Write-PSFMessage -Level System -Message "Using VacationRequestType '$($planningType)'" -Tag "VacationRequest", "Request", "VacationType"
        }
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "VacationRequest", "Request"

        if ($EmployeeName) {
            Write-PSFMessage -Level System -Message "Convert EmployeeId from EmployeeName" -Tag "VacationRequest", "Request", "EmployeeName"
            $EmployeeId = @()

            foreach ($name in $EmployeeName) {
                Write-PSFMessage -Level System -Message "Working on employee name '$($name)'" -Tag "VacationRequest", "Request", "EmployeeName"

                $id = ConvertFrom-NameCache -Name $name -Type "Employees"
                if (-not $id) {
                    Write-PSFMessage -Level Warning -Message "No Id for employee '$($name)' found" -Tag "VacationRequest", "Request", "EmployeeName", "Warning"
                } else {
                    Write-PSFMessage -Level System -Message "Found id '$($id)' for employee '$($name)'" -Tag "VacationRequest", "Request", "EmployeeName"
                }
                $EmployeeId += $id
            }
        }

        # Fallback to employeeId from token if no requestorId is set
        if (-not $EmployeeId) {
            Write-PSFMessage -Level Verbose -Message "No Employee specified, using current logged in employee '$($Token.UserName)' (Id:$($Token.EmployeeId))" -Tag "VacationRequest", "Request", "EmployeeId"
            $EmployeeId = $Token.EmployeeId
        }

        foreach ($requesterId in $EmployeeId) {
            Write-PSFMessage -Level System -Message "Request $planningType vacation object for id '$($id)' on dates '$(Get-Date -Date $StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $EndDate -Format 'yyyy-MM-dd')'" -Tag "VacationRequest", "Request"

            # gathering absence object
            $_startDate = [int][double]::Parse((Get-Date -Date $StartDate.Date.ToUniversalTime() -UFormat %s))
            $_endDate = [int][double]::Parse((Get-Date -Date $EndDate.Date.ToUniversalTime() -UFormat %s))

            $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/properties"
            $body = @{
                "requesterId"  = $requesterId
                "planningType" = $planningType
                "startDate"    = $_startDate
                "endDate"      = $_endDate
            }

            $plannedVactionRequest = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body -Token $Token -WhatIf:$false | Select-Object -ExpandProperty content
            if ($plannedVactionRequest) {
                Write-PSFMessage -Level Verbose -Message "Received VacationRequest object with $($plannedVactionRequest.days | Measure-Object | Select-Object -ExpandProperty Count) days on planningType '$($planningType)'" -Tag "VacationRequest", "VactionRequestObject"

                # output object
                [TANSS.Vacation.Request]@{
                    BaseObject = $plannedVactionRequest
                    Id         = $plannedVactionRequest.id
                }
            } else {
                Stop-PSFFunction -Message "Unable gathering '$($planningType)' VacationRequest object for employeeId '$($requesterId)' on dates '$(Get-Date -Date $StartDate -Format 'yyyy-MM-dd')'-'$(Get-Date -Date $EndDate -Format 'yyyy-MM-dd')' from '$($Token.Server)'" -Cmdlet $pscmdlet
            }
        }
    }

    end {}
}
