function Get-TANSSTicketActivity {
    <#
    .Synopsis
        Get-TANSSTicketActivity

    .DESCRIPTION
        Retreive support activities within a ticket

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .EXAMPLE
        Verb-Noun

        Description

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

            Get-TANSSTicketContent -TicketID $ticketIdItem -Type "Activity" -Token $Token | Select-Object -ExpandProperty Object
        }

    }

    end {
    }
}
