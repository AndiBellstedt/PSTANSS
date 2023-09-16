function Set-TANSSVacationRequestStatus {
    <#
    .Synopsis
        Set-TANSSVacationRequestStatus

    .DESCRIPTION
        Approve or decline a vacation request within TANSS

    .PARAMETER InputObject
        TANSS.Vacation.Request object to modify

    .PARAMETER Id
        The id of the vacation request to modify

    .PARAMETER Status
        Status to set for the request

        Available values are: "Approve", "Decline"
        Values can be tabcompleted, so you don't have to type

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
        PS C:\> Get-TANSSVacationRequest -Id 10 | Set-TANSSVacationRequestStatus -Status "Approve"

        Approve the VacationRequest Id 10

    .EXAMPLE
        PS C:\> Set-TANSSVacationRequestStatus -Id 10 -Status "Decline"

        Decline the VacationRequest Id 10

    .EXAMPLE
        PS C:\> $vacationRequests | Set-TANSSVacationRequestStatus -Status "Approve" -PassThru

        Approve all requests in variable '$vacationrequests' and output the (approved) VacationRequests on the console

        Assuming, the variable is build on something like:
        PS C:\>$vacationrequests = Get-TANSSVacationRequest -Year 2022 -Month 8

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ById",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([TANSS.Vacation.Request])]
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

        [Parameter(Mandatory = $true)]
        [ValidateSet("Approve", "Decline")]
        [string]
        $Status,

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
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        # If Id is piped in, query vacationRequests from TANSS
        if ($parameterSetName -like "ById") {
            $InputObject = foreach ($requesterId in $Id) {
                Write-PSFMessage -Level Verbose -Message "Query VacationRequestId $($requesterId)" -Tag "VacationRequest", "Query"

                # Query VacationRequest by ID
                $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/$($requesterId)"
                $response = Invoke-TANSSRequest -Type "GET" -ApiPath $apiPath -Token $Token -WhatIf:$false

                # Output result
                Write-PSFMessage -Level Verbose -Message "$($response.meta.text): VacationRequestId $($requesterId)" -Tag "VacationRequest", "Query"
                [TANSS.Vacation.Request]@{
                    BaseObject = $response.content
                    Id         = $response.content.id
                }
            }
        }

        if (-not $InputObject) {
            Write-PSFMessage -Level Significant -Message "No VacationRequests found to set status on" -Tag "VacationRequest", "Set", "NoData"
        } else {
            switch ($Status) {
                "Approve" {
                    $Status = "Approve" # Just to be sure with the spelling
                    $body = @{
                        "status" = "APPROVED"
                    }
                }

                "Decline" {
                    $Status = "Decline" # Just to be sure with the spelling
                    $body = @{
                        "status" = "DECLINED"
                    }
                }

                Default {
                    Stop-PSFFunction -Message "Unhandled status '$($Status)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "SwitchException", "ParameterSet"
                }
            }

            foreach ($vacationRequest in $InputObject) {

                if ($pscmdlet.ShouldProcess("VacationRequestId '$($vacationRequest.Id)' from '$($vacationRequest.EmployeeName)' on '$($vacationRequest.StartDate)-$($vacationRequest.EndDate)'", $Status)) {
                    Write-PSFMessage -Level Verbose -Message "$($Status) VacationRequestId '$($vacationRequest.Id)' from '$($vacationRequest.EmployeeName)' on '$($vacationRequest.StartDate)-$($vacationRequest.EndDate)'" -Tag "VacationRequest", "Set", $Status

                    # Set status on VacationRequest
                    $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/$($vacationRequest.Id)"
                    $response = Invoke-TANSSRequest -Type "PUT" -ApiPath $apiPath -Body $body -Token $Token -WhatIf:$false
                    Write-PSFMessage -Level Verbose -Message "VacationRequestId '$($vacationRequest.Id)' - $($response.meta.text)" -Tag "VacationRequest", "Set"

                    # Output if Passthrough is set
                    if($PassThru) {
                        [TANSS.Vacation.Request]@{
                            BaseObject = $response.content
                            Id         = $response.content.id
                        }
                    }
                }
            }
        }
    }

    end {
    }
}
