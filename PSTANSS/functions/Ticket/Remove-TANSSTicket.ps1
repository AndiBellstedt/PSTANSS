function Remove-TANSSTicket {
    <#
    .Synopsis
        Remove-TANSSTicket

    .DESCRIPTION
        Delete a ticket in TANSS

    .PARAMETER Token
        The TANSS.Connection token

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        Remove-TANSSTicket -ID 10

        Remove ticket with ticketID 10 from TANSS

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'ById',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        # TANSS Ticket object to remove
        [Parameter(
            ParameterSetName = "ByInputObject",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [TANSS.Ticket[]]
        $InputObject,

        # Id of the ticket to remove
        [Parameter(
            ParameterSetName = "ById",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("TicketId", "Ticket")]
        [int[]]
        $Id,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        if ($parameterSetName -like "ById") {
            $InputObject = foreach ($idItem in $Id) {
                Get-TANSSTicket -Id $idItem -ErrorAction Continue
            }
        }

        foreach ($ticket in $InputObject) {
            Write-PSFMessage -Level Verbose -Message "Working on TicketID $($ticket.Id) '$($ticket.Title)'"
            $apiPath = Format-ApiPath -Path "api/v1/tickets/$($ticket.Id)"

            if ($pscmdlet.ShouldProcess("TicketID $($ticket.Id) '$($ticket.Title)' from TANSS", "Remove")) {
                Write-PSFMessage -Level Verbose -Message "Removing TicketID $($ticket.Id) '$($ticket.Title)' from TANSS" -Tag "Ticket"

                Invoke-TANSSRequest -Type DELETE -ApiPath $apiPath -Token $Token -ErrorAction Stop -ErrorVariable invokeError
            }
        }
    }

    end {
    }
}