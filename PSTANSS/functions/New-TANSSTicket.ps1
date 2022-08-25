function New-TANSSTicket {
    <#
    .Synopsis
       New-TANSSTicket

    .DESCRIPTION
       Creates a ticket in the database

    .PARAMETER Server
        Name of the service to connect to

    .PARAMETER Token
        The TANSS.Connection token

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
       New-TANSSTicket -Title "A new Ticket"

       Create a ticket

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Credential',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    #[Parameter(ParameterSetName = 'ByCompany', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0)]
    param (
        # Company id of the ticket. Name is stored in the "linked entities" - "companies". Can only be set if the user has access to the company
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [int]
        $CompanyId,

        # If the ticket has a remitter, the id goes here. Name is stored in the "linked entities" - "employees"
        [int]
        $RemitterId,

        # gives infos about how the remitter gave the order. Infos are stored in the "linked entities" - "orderBys"
        [int]
        $OrderById,

        # The title / subject of the ticket
        [Parameter(Mandatory = $true)]
        [string]
        $Title,

        # The content / description of the ticket
        [Alias('content')]
        [string]
        $Description,

        # External ticket id (optional)
        [Alias('extTicketId')]
        [string]
        $ExternalTicket,

        # id of employee which ticket is assigned to. Name is stored in "linked entities" - "employees"
        [Alias('assignedToEmployeeId')]
        [int]
        $EmployeeIdAssigned,

        # id of department which ticket is assigned to. Name is stored in "linked entities" - "departments"
        [Alias('assignedToDepartmentId')]
        [int]
        $DepartmentIdAssigned,

        # id of the ticket state. Name is give in "linked entities" - "ticketStates"
        [int]
        $StatusId,

        # id of the ticket type. Name is give in "linked entities" - "ticketTypes"
        [int]
        $TypeId,

        # if ticket is assigned to device / employee, linktype is given here
        [Alias('LinkTypeId')]
        [int]
        $AssignmentId,

        # If ticket has a deadline, the date is given here
        [Alias('deadlineDate')]
        [datetime]
        $Deadline,

        # if ticket is actually a project, this value is true
        [Alias('project')]
        [bool]
        $IsProject = $false,

        # if ticket is a sub-ticket of a project, the id of the project goes here. Name of the project is in the "linked entities" - "tickets"
        [int]
        $ProjectId,

        # if the ticket is assignet to a project phase. The name of the phase is stored in the "linked entities" - "phases"
        [Int]
        $PhaseId,

        # if true, this ticket is a "repair ticket"
        [Alias('repair')]
        [bool]
        $IsRepair = $false,

        # if ticket has a due date, the timestamp is given here
        [datetime]
        $DueDate,

        # Determines the "attention" flag state of a ticket
        [ValidateSet("NO", "YES", "RESUBMISSION", "MAIL")]
        [string]
        $Attention = "NO",

        # If the ticket has an installation fee, this value is true
        [ValidateSet("NO", "YES", "NO_PROJECT_INSTALLATION_FEE")]
        [string]
        $InstallationFee = "NO",

        # Sets the installation fee drive mode. If it is set to NONE then the system config parameter "leistung.ip.fahrzeit_berechnen" will be used. If the company from the ticket has an installation fee drive mode set then that will be used instead of the system config parameter.
        [ValidateSet("NONE", "DRIVE_INCLUDED", "DRIVE_EXCLUDED")]
        [string]
        $InstallationFeeDriveMode = "NONE",


        #Amount for the installation fee
        [int]
        $InstallationFeeAmount,


        # If true, the ticket shall be billed separately
        [bool]
        $SeparateBilling = $false,

        # if the ticket has a service cap, here the amount is given
        [int]
        $ServiceCapAmount,

        # linkId of the relationship (if ticket has a relation)
        [int]
        $RelationshipLinkId,

        # linkTypeId of the relationship (if ticket has a relation)
        [int]
        $RelationshipLinkTypeId,

        # if the ticket as a resubmission date set, this is given here
        [datetime]
        $ResubmissionDate,

        # If a resubmission text is set, this text is returned here
        [string]
        $ResubmissionText,

        # Number of estimated minutes which is planned for the ticket
        [int]
        $EstimatedMinutes,

        # Determines wether the ticket is assigned to a local ticket admin or not
        # NONE: "normal" ticket
        # LOCAL_ADMIN: ticket is assigned to a local ticket admin
        # TECHNICIAN: local ticket admin has forwarded the ticket to a technician
        [ValidateSet("NONE", "LOCAL_ADMIN", "TECHNICIAN")]
        [string]
        $LocalTicketAdminFlag = "NONE",


        # if the ticket is assigned to a local ticket admin, this represents the employee (local ticket admin) who is assigned for this ticket
        [int]
        $LocalTicketAdminEmployeeId,

        # Sets the order number
        [string]
        $OrderNumber,

        # If the ticket has a reminder set, the timestamp is returned here
        [datetime]
        $Reminder,

        # When persisting a ticket, you can also send a list of tag assignments which will be assigned to the ticket
        [string[]]
        $Tags,

        # path for API
        [string]
        $ApiPath = "backend/api/v1/tickets",

        [TANSS.Connection]
        $Token
    )

    begin {
        if(-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
    }

    process {
        #region rest call prepare
        if ($Deadline) {
            $_deadlineDate = [int][double]::Parse((Get-Date -Date $Deadline -UFormat %s))
        } else {
            $_deadlineDate = 0
        }

        if ($ResubmissionDate) {
            $_resubmissionDate = [int][double]::Parse((Get-Date -Date $ResubmissionDate -UFormat %s))
        } else {
            $_resubmissionDate = 0
        }

        if ($Reminder) {
            $_reminder = [int][double]::Parse((Get-Date -Date $Reminder -UFormat %s))
        } else {
            $_reminder = 0
        }

        $body = [ordered]@{
            companyId                  = $CompanyId
            remitterId                 = $RemitterId
            orderById                  = $OrderById
            title                      = "$($Title)"
            content                    = "$($Description)"
            extTicketId                = "$($ExternalTicket)"
            assignedToEmployeeId       = $EmployeeIdAssigned
            assignedToDepartmentId     = $DepartmentIdAssigned
            statusId                   = $StatusId
            typeId                     = $TypeId
            linkTypeId                 = $AssignmentId
            deadlineDate               = $_deadlineDate
            project                    = $IsProject
            projectId                  = $ProjectId
            phaseId                    = $PhaseId
            repair                     = $IsRepair
            dueDate                    = $DueDate
            attention                  = $Attention
            installationFee            = $InstallationFee
            installationFeeDriveMode   = $InstallationFeeDriveMode
            installationFeeAmount      = $InstallationFeeAmount
            separateBilling            = $SeparateBilling
            serviceCapAmount           = $ServiceCapAmount
            relationshipLinkTypeId     = $RelationshipLinkTypeId
            relationshipLinkId         = $RelationshipLinkId
            resubmissionDate           = $_resubmissionDate
            resubmissionText           = "$($ResubmissionText)"
            estimatedMinutes           = $EstimatedMinutes
            localTicketAdminFlag       = $LocalTicketAdminFlag
            localTicketAdminEmployeeId = $LocalTicketAdminEmployeeId
            orderNumber                = "$($OrderNumber)"
            reminder                   = $_reminder
            #subTickets                 = @{}
            tags                       = $Tags
        }
        #endregion rest call prepare

        if ($pscmdlet.ShouldProcess("Ticket with Title '$($Title)' on companyID '$($CompanyId)'", "New")) {
            Write-PSFMessage -Level Verbose -Message "Creating Ticket with Title '$($Title)' on companyID '$($CompanyId)'" -Tag "Ticket" -Data $body

            $response = Invoke-TANSSRequest -Type POST -ApiPath $ApiPath -Body $body -Token $Token

            if($response) {
                Write-PSFMessage -Level Verbose -Message "API Response: $($response.meta.text)"

                $output = $response.content
                $output.psobject.TypeNames.Insert(0, "TANSS.Ticket")

                $output
            } else {
                Write-PSFMessage -Level Error -Message "Error creating ticket, no ticket response from API"
            }
        }
    }

    end {
    }
}