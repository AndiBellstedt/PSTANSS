function Remove-TANSSVacationRequest {
    <#
    .Synopsis
        Remove-TANSSVacationRequest

    .DESCRIPTION
        Remove a vacation request

    .PARAMETER Force
        Process the removal quietly.

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Get-TANSSVacationRequest -Id 10 | Remove-TANSSVacationRequest

        Remove the VacationRequest Id 10

    .EXAMPLE
        PS C:\> Remove-TANSSVacationRequest -Id 10 -Force

        Remove the VacationRequest Id 10 without asking for confirmation

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ById",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'High'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ByInputObject",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [TANSS.Vacation.Request[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ById",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias("RequestId", "VacationRequestId")]
        [int[]]
        $Id,

        [switch]
        $Force,

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

        # If Id is piped in, query vacationRequests from TANSS
        if ($parameterSetName -like "ById") {
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

        if (-not $InputObject) {
            Write-PSFMessage -Level Error -Message "No VacationRequests to remove" -Tag "VacationRequest", "Set", "NoData" -PSCmdlet $pscmdlet
        } else {
            $processRemoval = $false

            foreach ($vacationRequest in $InputObject) {

                # Check on Force parameter, otherwise process shouldprocess
                if ($Force) {
                    $processRemoval = $true
                } else {
                    if ($pscmdlet.ShouldProcess("VacationRequestId '$($vacationRequest.Id)' from '$($vacationRequest.EmployeeName)' on '$($vacationRequest.StartDate)-$($vacationRequest.EndDate)'", "Remove")) {
                        $processRemoval = $true
                    }
                }

                if ($processRemoval) {
                    Write-PSFMessage -Level Verbose -Message "Remove VacationRequestId '$($vacationRequest.Id)' from '$($vacationRequest.EmployeeName)' on '$($vacationRequest.StartDate)-$($vacationRequest.EndDate)'" -Tag "VacationRequest", "Set", "Remove"

                    # Remove VacationRequest
                    $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/$($vacationRequest.Id)"
                    $response = Invoke-TANSSRequest -Type DELETE -ApiPath $apiPath -Token $Token -Confirm:$false
                }
            }
        }
    }

    end {
    }
}
