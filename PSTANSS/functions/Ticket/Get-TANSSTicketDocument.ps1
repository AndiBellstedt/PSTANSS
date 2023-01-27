function Get-TANSSTicketDocument {
    <#
    .Synopsis
        Get-TANSSTicketDocument

    .DESCRIPTION
        Retreive documents within a ticket

    .PARAMETER TicketID
        The ID of the ticket to receive documents of

    .PARAMETER Ticket
        TANSS.Ticket object to receive documents of

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSTicketDocument -TicketID 555

        Get all documents from ticket 555

    .EXAMPLE
        PS C:\> $tickets | Get-TANSSTicketDocument

        Get all documents from all tickets from variable $tickets

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ByTicketId",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ByTicketId",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [int[]]
        $TicketID,

        [Parameter(
            ParameterSetName = "ByTicket",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.Ticket[]]
        $Ticket,

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

        if ($parameterSetName -like "ByTicket") {
            $inputobjectTicketCount = ([array]$Ticket).Count
            Write-PSFMessage -Level System -Message "Getting IDs of $($inputobjectTicketCount) ticket$(if($inputobjectTicketCount -gt 1){'s'})"  -Tag "TicketComment", "CollectInputObjects"
            [array]$TicketID = $Ticket.id
        }

        foreach ($ticketIdItem in $TicketID) {
            Write-PSFMessage -Level Verbose -Message "Working on ticket ID $($ticketIdItem)"  -Tag "TicketComment", "Query"

            Get-TANSSTicketContent -TicketID $ticketIdItem -Type "Document" -Token $Token | Select-Object -ExpandProperty Object
        }

    }

    end {
    }
}
