function Get-TANSSTicketType {
    <#
    .Synopsis
        Get-TANSSTicketType

    .DESCRIPTION
        Get the various types of a ticket from tanss

    .PARAMETER Id
        The Id of the ticket type to get

    .PARAMETER Name
        The name of the ticket type to get

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSTicketType

        Get the available ticket types

    .EXAMPLE
        PS C:\> Get-TANSSTicketType -Id 2

        Get the tiket types with Id 2

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
    [OutputType([TANSS.TicketType])]
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

        $apiPath = Format-ApiPath -Path "api/v1/tickets/types"
        $ticketTypes = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token | Select-Object -ExpandProperty content


        [array]$filteredTicketTypes = @()
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        switch ($parameterSetName) {
            "ById" {
                foreach ($item in $Id) {
                    $filteredTicketTypes += $ticketTypes | Where-Object id -eq $item
                }
            }

            "ByName" {
                foreach ($item in $Name) {
                    $filteredTicketTypes += $ticketTypes | Where-Object name -like $item
                }
            }

            "All" {
                $filteredTicketTypes = $ticketTypes
            }

            Default {
                Stop-PSFFunction -Message "Unhandled ParameterSet '$($parameterSetName)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "TicketType", "SwitchException", "ParameterSet"
            }
        }
    }

    end {
        $filteredTicketTypes = $filteredTicketTypes | Sort-Object Name, id -Unique
        Write-PSFMessage -Level Verbose -Message "Going to return $($filteredTicketTypes.count) ticket status" -Tag "TicketType", "Output"

        foreach ($ticketType in $filteredTicketTypes) {
            Write-PSFMessage -Level System -Message "Working on TicketType '$($ticketType.name)' with id '$($ticketType.id)'" -Tag "TicketType"

            # put id and name to cache lookups
            Update-CacheLookup -LookupName "TicketTypes" -Id $ticketType.Id -Name $ticketType.Name

            # output result
            [TANSS.TicketType]@{
                Baseobject = $ticketType
                Id = $ticketType.id
            }
        }
    }
}
