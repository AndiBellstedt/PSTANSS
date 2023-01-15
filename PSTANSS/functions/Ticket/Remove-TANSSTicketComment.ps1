function Remove-TANSSTicketComment {
    <#
    .Synopsis
        Remove-TANSSTicketComment

    .DESCRIPTION
        Remove a comment from a ticket

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
        PS C:\> Verb-Noun

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ByTicketId",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'High'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ById",
            Mandatory = $true
        )]
        [int]
        $TicketID,

        [Parameter(
            ParameterSetName = "ById",
            Mandatory = $true
        )]
        [Alias("CommentID")]
        [int]
        $Id,

        [Parameter(
            ParameterSetName = "ByInputObject",
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.TicketComment]
        $Comment,

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

        if ($parameterSetName -like "ByInputObject") {
            $TicketID = $Comment.TicketId
            $Id = $Comment.Id
        }


        # Check on Force parameter, otherwise process shouldprocess
        if ($Force) {
            $processRemoval = $true
        } else {
            if ($pscmdlet.ShouldProcess("comment ID $($Id) from ticket ID $($TicketID)", "Remove")) {
                $processRemoval = $true
            }
        }

        if ($processRemoval) {
            Write-PSFMessage -Level Verbose -Message "Remove comment ID $($Id) from ticket ID $($TicketID)" -Tag "TicketComment", "Remove"

            # Remove comment from ticket
            $apiPath = Format-ApiPath -Path "api/v1/tickets/$($TicketID)/comments/$($Id)"
            Invoke-TANSSRequest -Type DELETE -ApiPath $apiPath -Token $Token -Confirm:$false
        }
    }

    end {}
}
