function Get-TANSSTicket {
    <#
    .Synopsis
        Get-TANSSTicket

    .DESCRIPTION
        Gat a ticket from TANSS service

    .PARAMETER Id
        The ticket Id (one or more) to query

    .PARAMETER CompanyId
        Get all tickets of company Id

    .PARAMETER MyTickets
        Get all tickets assigned to the authenticated account

    .PARAMETER NotAssigned
        Get all tickets not assigned to somebody

    .PARAMETER AllTechnician
        Get all tickets assigned to somebody

    .PARAMETER RepairTickets
        Get tickets marked as repair tickets

    .PARAMETER NotIdentified
        Get all unidentified tickets

    .PARAMETER Project
        Get tickets marked as a project

    .PARAMETER LocalTicketAdmin
        Get all tickets specified for a ticket admin

    .PARAMETER TicketWithTechnicianRole
        Get all tickets with a technician role

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSTicket

        Get all tickets assinged to the authenticated user

    .EXAMPLE
        PS C:\> Get-TANSSTicket -Id 100

        Get ticket with Id 100

    .EXAMPLE
        PS C:\> Get-TANSSTicket -CompanyId 12345

        Get all tickets of company Id 12345

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding(
        DefaultParameterSetName = 'MyTickets',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    [OutputType([TANSS.Ticket], [TANSS.Project])]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "TicketId"
        )]
        [int[]]
        $Id,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "CompanyId"
        )]
        [int[]]
        $CompanyId,


        [Parameter(
            Mandatory = $false,
            ParameterSetName = "MyTickets"
        )]
        [Alias("Own", "OwnTickets", "MyOwn", "NyOwnTickets")]
        [switch]
        $MyTickets,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "NotAssigned"
        )]
        [Alias("General", "GeneralTickets")]
        [switch]
        $NotAssigned,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "AllTechnician"
        )]
        [Alias("TicketsAllTechnicians", "Assigned", "AssignedTickets")]
        [switch]
        $AllTechnician,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "RepairTickets"
        )]
        [switch]
        $RepairTickets,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "NotIdentified"
        )]
        [switch]
        $NotIdentified,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Projects"
        )]
        [switch]
        [Alias("AllProjects")]
        $Project,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "LocalTicketAdmin"
        )]
        [Alias("AssignedToTicketAdmin")]
        [switch]
        $LocalTicketAdmin,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "TicketWithTechnicianRole"
        )]
        [switch]
        $TicketWithTechnicianRole,

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
        $response = @()

        # Construct query
        switch ($parameterSetName) {
            "TicketId" {
                # in case of "Query by Id" -> Do the query now
                $response += foreach ($ticketId in $Id) {
                    Invoke-TANSSRequest -Type GET -ApiPath "api/v1/tickets/$($ticketId)" -Token $Token
                }
            }

            "CompanyId" {
                # in case of "Query by CompanyId" -> Do the query now
                $response += foreach ($_companyId in $CompanyId) {
                    Invoke-TANSSRequest -Type GET -ApiPath "api/v1/tickets/company/$($_companyId)" -Token $Token
                }
            }

            "MyTickets" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/own"
            }

            "NotAssigned" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/general"
            }

            "AllTechnician" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/technician"
            }

            "RepairTickets" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/repair"
            }

            "NotIdentified" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/notIdentified"
            }

            "Projects" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/projects"
            }

            "LocalTicketAdmin" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/localAdminOverview"
            }

            "TicketWithTechnicianRole" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/withRole"
            }

            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }

        # Do the constructed query, as long, as variable apiPath has a value
        if ($apiPath) {
            $response += Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token
        }

        if ($response) {
            Write-PSFMessage -Level Verbose -Message "Found $(($response.content).count) tickets"

            # Push meta to cache runspace
            foreach ($responseItem in $response) {
                Push-DataToCacheRunspace -MetaData $responseItem.meta

                # Output result
                foreach($ticket in $responseItem.content) {
                    if($parameterSetName -like "Projects") {
                        [TANSS.Project]@{
                            BaseObject = $ticket
                            Id = $ticket.id
                        }
                    } else {
                        [TANSS.Ticket]@{
                            BaseObject = $ticket
                            Id = $ticket.id
                        }
                    }
                }

            }
        } else {
            Write-PSFMessage -Level Warning -Message "No tickets found." -Tag "Ticket"
        }
    }

    end {
    }
}
