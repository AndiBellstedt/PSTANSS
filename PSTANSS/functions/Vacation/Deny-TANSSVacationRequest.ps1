function Deny-TANSSVacationRequest {
    <#
    .Synopsis
        Deny-TANSSVacationRequest

    .DESCRIPTION
        Decline a vacation request within TANSS

    .PARAMETER InputObject
        TANSS.Vacation.Request object to approve

    .PARAMETER Id
        Id of the vacation request to approve

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
        PS C:\> Get-TANSSVacationRequest -Id 10 | Deny-TANSSVacationRequest

        Decline the VacationRequest Id 10

    .EXAMPLE
        PS C:\> Deny-TANSSVacationRequest -Id 10

        Decline the VacationRequest Id 10

    .EXAMPLE
        PS C:\> $vacationRequests | Deny-TANSSVacationRequest -PassThru

        Decline all requests in variable '$vacationrequests' and output the new (declined) VacationRequests on the console

        Assuming, the variable is build on something like:
        PS C:\>$vacationrequests = Get-TANSSVacationRequest -Year 2022 -Month 8

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
    [CmdletBinding(
        DefaultParameterSetName = "ById",
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
        $PassThru,

        [TANSS.Connection]
        $Token
    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Set-TANSSVacationRequestStatus', [System.Management.Automation.CommandTypes]::Function)
            $scriptCmd = {& $wrappedCmd -Status "Decline" @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline()
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}
