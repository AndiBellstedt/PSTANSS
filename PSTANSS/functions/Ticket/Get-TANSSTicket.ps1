function Get-TANSSTicket {
    <#
    .Synopsis
       Get-TANSSTicket

    .DESCRIPTION
       Retrieve the registered LoginToken for default TANSS connection

    .PARAMETER Token
        The TANSS.Connection token

    .EXAMPLE
       Get-TANSSTicket

       Get tickets

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'TicketId',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
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
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "CompanyId"
        )]
        [int[]]
        $CompanyId,


        [Parameter(
            Mandatory = $true,
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
        $Projects,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "LocalTicketAdmin"
        )]
        [Alias("AssignedToTicketAdmin")]
        [switch]
        $LocalTicketAdmin,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "TicketWithTechnicanRole"
        )]
        [switch]
        $TicketWithTechnicanRole,



        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
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
                    $apiPath = Format-ApiPath -Path "api/v1/tickets/$($ticketId)"
                    Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token
                }

                # Clear variable apiPath to indicate, that the query is already done
                $apiPath = ""
            }

            "CompanyId" {
                # in case of "Query by CompanyId" -> Do the query now
                $response += foreach ($_companyId in $CompanyId) {
                    $apiPath = Format-ApiPath -Path "api/v1/tickets/company/$($_companyId)"
                    Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token
                }

                # Clear variable apiPath to indicate, that the query is already done
                $apiPath = ""
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

            "TicketWithTechnicanRole" {
                $apiPath = Format-ApiPath -Path "api/v1/tickets/withRole"
            }

            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true
                throw
            }
        }

        # Do the constructed query, as long, as variable apiPath has a value
        if($apiPath) {
            $response += Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token
        }

        if($response) {
            Write-PSFMessage -Level Verbose -Message "Found $(($response.content).count) tickets"

            # Push meta to cache runspace
            foreach($item in $response) {
                #ToDo runspace

                # Output result
                $response
            }
        } else {
            Write-PSFMessage -Level Warning -Message "No tickets found." -Tag "Ticket"
        }
    }

    end {
    }
}
