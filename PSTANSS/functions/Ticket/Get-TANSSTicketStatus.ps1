function Get-TANSSTicketStatus {
    <#
    .Synopsis
        Get-TANSSTicketStatus

    .DESCRIPTION
        Get the various status types of a ticket from tanss

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Verb-Noun

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "All",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "ById"
        )]
        [int[]]
        $Id,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "ByName"
        )]
        [string[]]
        $Name,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }

        Assert-CacheRunspaceRunning

        $apiPath = Format-ApiPath -Path "api/v1/tickets/status"
        $ticketStates = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token | Select-Object -ExpandProperty content


        [array]$filteredTicketStates = @()
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        switch ($parameterSetName) {
            "ById" {
                foreach ($item in $Id) {
                    $filteredTicketStates += $ticketStates | Where-Object id -eq $item
                }
            }

            "ByName" {
                foreach ($item in $Name) {
                    $filteredTicketStates += $ticketStates | Where-Object name -like $item
                }
            }

            "All" {
                $filteredTicketStates = $ticketStates
            }

            Default {
                Stop-PSFFunction -Message "Unhandled ParameterSet '$($parameterSetName)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "TicketStatus", "SwitchException", "ParameterSet"
            }
        }
    }

    end {
        $filteredTicketStates = $filteredTicketStates | Sort-Object rank, id -Unique
        Write-PSFMessage -Level Verbose -Message "Going to return $($filteredTicketStates.count) ticket status" -Tag "TicketStatus", "Output"

        foreach ($ticketStatus in $filteredTicketStates) {
            Write-PSFMessage -Level System -Message "Working on ticketstatus '$($ticketStatus.name)' with id '$($ticketStatus.id)'" -Tag "TicketStatus"

            # put id and name to cache lookups
            Update-CacheLookup -LookupName "TicketStates" -Id $ticketStatus.Id -Name $ticketStatus.Name

            # output result
            [TANSS.TicketStatus]@{
                Baseobject = $ticketStatus
                Id = $ticketStatus.id
            }
        }
    }
}
