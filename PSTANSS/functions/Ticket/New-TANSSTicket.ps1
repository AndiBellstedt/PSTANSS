function New-TANSSTicket {
    <#
    .Synopsis
        New-TANSSTicket

    .DESCRIPTION
        Creates a ticket in the database

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
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Userfriendly",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        # Company id of the ticket. Name is stored in the "linked entities" - "companies". Can only be set if the user has access to the company
        [Parameter(ParameterSetName="ApiNative")]
        [int]
        $CompanyId,

        # Company name where the ticket should create for. Can only be set if the user has access to the company
        [Parameter(ParameterSetName="Userfriendly")]
        [String]
        $Company,

        # If the ticket has a remitter, the id goes here. Name is stored in the "linked entities" - "employees"
        [Parameter(ParameterSetName="ApiNative")]
        [Alias('ClientId')]
        [int]
        $RemitterId,

        # If the ticket has a remitter/client, the name of the client
        [Parameter(ParameterSetName="Userfriendly")]
        [String]
        $Client,

        # gives infos about how the remitter gave the order. Infos are stored in the "linked entities" - "orderBys"
        [Parameter(ParameterSetName="ApiNative")]
        [int]
        $OrderById,

        # gives infos about how the Client gave the order.
        [Parameter(ParameterSetName="Userfriendly")]
        [string]
        $OrderBy,

        # The title / subject of the ticket
        [Parameter(
            ParameterSetName="Userfriendly",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true

        )]
        [Parameter(
            ParameterSetName="ApiNative",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true

        )]
        [string]
        $Title,

        # The content / description of the ticket
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [Alias('content')]
        [string]
        $Description,

        # External ticket id (optional)
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [Alias('extTicketId')]
        [string]
        $ExternalTicketId,

        # id of employee which ticket is assigned to. Name is stored in "linked entities" - "employees"
        [Parameter(ParameterSetName="ApiNative")]
        [Alias('assignedToEmployeeId')]
        [int]
        $EmployeeIdAssigned,

        # Name of the employee the ticket is assigned to
        [Parameter(ParameterSetName="Userfriendly")]
        [String]
        $EmployeeAssigned,

        # id of department the ticket is assigned to. Name is stored in "linked entities" - "departments"
        [Parameter(ParameterSetName="ApiNative")]
        [Alias('assignedToDepartmentId')]
        [int]
        $DepartmentIdAssigned,

        # Name of the department the ticket is assigned to
        [Parameter(ParameterSetName="Userfriendly")]
        [String]
        $Department,

        # id of the ticket state. Name is give in "linked entities" - "ticketStates"
        [Parameter(ParameterSetName="ApiNative")]
        [int]
        $StatusId,

        # The name of the ticket status
        [Parameter(ParameterSetName="Userfriendly")]
        [String]
        $Status,

        # id of the ticket type. Name is give in "linked entities" - "ticketTypes"
        [Parameter(ParameterSetName="ApiNative")]
        [int]
        $TypeId,

        # The name of the ticket type
        [Parameter(ParameterSetName="Userfriendly")]
        [String]
        $Type,

        # if ticket is assigned to device / employee, linktype is given here
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [Alias('LinkTypeId')]
        [int]
        $AssignmentId,

        # If ticket has a deadline, the date is given here
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [Alias('deadlineDate')]
        [datetime]
        $Deadline,

        # if ticket is actually a project, this value is true
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [Alias('project')]
        [bool]
        $IsProject = $false,

        # if ticket is a sub-ticket of a project, the id of the project goes here. Name of the project is in the "linked entities" - "tickets"
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [int]
        $ProjectId,

        # if the ticket is assignet to a project phase. The name of the phase is stored in the "linked entities" - "phases"
        [Parameter(ParameterSetName="ApiNative")]
        [Int]
        $PhaseId,

        # if the ticket is assignet to a project phase, the name of the phase
        [Parameter(ParameterSetName="Userfriendly")]
        [String]
        $Phase,

        # if true, this ticket is a "repair ticket"
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [Alias('repair')]
        [bool]
        $IsRepair = $false,

        # if ticket has a due date, the timestamp is given here
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [datetime]
        $DueDate,

        # Determines the "attention" flag state of a ticket
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [ValidateSet("NO", "YES", "RESUBMISSION", "MAIL")]
        [string]
        $Attention = "NO",

        # If the ticket has an installation fee, this value is true
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [ValidateSet("NO", "YES", "NO_PROJECT_INSTALLATION_FEE")]
        [string]
        $InstallationFee = "NO",

        # Sets the installation fee drive mode. If it is set to NONE then the system config parameter "leistung.ip.fahrzeit_berechnen" will be used. If the company from the ticket has an installation fee drive mode set then that will be used instead of the system config parameter.
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [ValidateSet("NONE", "DRIVE_INCLUDED", "DRIVE_EXCLUDED")]
        [string]
        $InstallationFeeDriveMode = "NONE",

        #Amount for the installation fee
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [int]
        $InstallationFeeAmount,

        # If true, the ticket shall be billed separately
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [bool]
        $SeparateBilling = $false,

        # if the ticket has a service cap, here the amount is given
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [int]
        $ServiceCapAmount,

        # linkId of the relationship (if ticket has a relation)
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [int]
        $RelationshipLinkId,

        # linkTypeId of the relationship (if ticket has a relation)
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [int]
        $RelationshipLinkTypeId,

        # if the ticket as a resubmission date set, this is given here
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [datetime]
        $ResubmissionDate,

        # If a resubmission text is set, this text is returned here
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [string]
        $ResubmissionText,

        # Number of estimated minutes which is planned for the ticket
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [int]
        $EstimatedMinutes,

        # Determines wether the ticket is assigned to a local ticket admin or not
        # NONE: "normal" ticket
        # LOCAL_ADMIN: ticket is assigned to a local ticket admin
        # TECHNICIAN: local ticket admin has forwarded the ticket to a technician
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [ValidateSet("NONE", "LOCAL_ADMIN", "TECHNICIAN")]
        [string]
        $LocalTicketAdminFlag = "NONE",

        # if the ticket is assigned to a local ticket admin, this represents the employee (local ticket admin) who is assigned for this ticket
        [Parameter(ParameterSetName="ApiNative")]
        [int]
        $LocalTicketAdminEmployeeId,

        # if the ticket is assigned to a local ticket admin, this represents the name of the employee (local ticket admin) who is assigned for this ticket
        [Parameter(ParameterSetName="Userfriendly")]
        [ValidateNotNullOrEmpty]
        [String]
        $EmployeeTicketAdmin,

        # Sets the order number
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [string]
        $OrderNumber,

        # If the ticket has a reminder set, the timestamp is returned here
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [datetime]
        $Reminder,

        # When persisting a ticket, you can also send a list of tag assignments which will be assigned to the ticket
        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName="ApiNative")]
        [Parameter(ParameterSetName="Userfriendly")]
        [TANSS.Connection]
        $Token
    )

    begin {
        if(-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
        $apiPath = Format-ApiPath -Path "api/v1/tickets"

        if($EmployeeTicketAdmin) {
            $LocalTicketAdminEmployeeId = ConvertFrom-NameCache -Name $EmployeeTicketAdmin -Type "Employees"
            if(-not $LocalTicketAdminEmployeeId) {
                Write-PSFMessage -Level Warning -Message "No Id for employee '$($EmployeeTicketAdmin)' found. Ticket will be created with blank value on TicketAdminEmployee"
                #todo implement API call for employee
            }
        }

        if($EmployeeAssigned) {
            $EmployeeIdAssigned = ConvertFrom-NameCache -Name $EmployeeAssigned -Type "Employees"
            if(-not $EmployeeIdAssigned) {
                Write-PSFMessage -Level Warning -Message "No Id for employee '$($EmployeeAssigned)' found. Ticket will be created with blank value on EmployeeIdAssigned"
                #todo implement API call for employee
            }
        }

        if($Client) {
            $RemitterId = ConvertFrom-NameCache -Name $Client -Type "Employees"
            if(-not $RemitterId) {
                Write-PSFMessage -Level Warning -Message "No Id for client '$($Client)' found. Ticket will be created with blank value on RemitterId"
                #todo implement API call for employee
            }
        }

        if($Phase) {
            $PhaseId = ConvertFrom-NameCache -Name $Phase -Type "Phases"
            if(-not $PhaseId) {
                Write-PSFMessage -Level Warning -Message "No Id for phase '$($Phase)' found. Ticket will be created with blank value on Phase"
            }
        }

        if($Type) {
            $TypeId = ConvertFrom-NameCache -Name $Type -Type "TicketTypes"
            if(-not $TypeId) {
                Write-PSFMessage -Level Warning -Message "No Id for ticket type '$($Type)' found. Ticket will be created with blank value on TicketType"
            }
        }

        if ($OrderBy) {
            $OrderById = ConvertFrom-NameCache -Name $OrderBy -Type "OrderBys"
            if (-not $OrderById) {
                Write-PSFMessage -Level Warning -Message "No Id for OrderBy type '$($OrderBy)' found. Ticket will be created with blank value on OrderById"
            }
        }

        if($Status) {
            $StatusId = ConvertFrom-NameCache -Name $Status -Type "TicketStates"
            if(-not $StatusId) {
                Write-PSFMessage -Level Warning -Message "No Id for ticket state '$($Status)' found. Ticket will be created with blank value on TicketStatus"
            }
        }

        if($Department) {
            $DepartmentIdAssigned = ConvertFrom-NameCache -Name $Department -Type "Departments"
            if(-not $DepartmentIdAssigned) {
                Write-PSFMessage -Level Warning -Message "No Id for department '$($Department)' found. Ticket will be created with blank value on departmentIdAssigned"
            }
        }

        if($Company) {
            $CompanyId = ConvertFrom-NameCache -Name $Company -Type "Companies"
            if(-not $CompanyId) {
                Write-PSFMessage -Level Warning -Message "No Id for company '$($Company)' found. Ticket will be created with blank value on CompanyId"
            }
        }

    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        if ($parameterSetName -like "Userfriendly" -and (-not $Title)) {
            Write-PSFMessage -Level Error -Message "No title specified"
            continue
        }

        #region rest call prepare
        if ($Deadline) {
            $_deadlineDate = [int][double]::Parse((Get-Date -Date $Deadline.ToUniversalTime() -UFormat %s))
        } else {
            $_deadlineDate = 0
        }

        if ($ResubmissionDate) {
            $_resubmissionDate = [int][double]::Parse((Get-Date -Date $ResubmissionDate.ToUniversalTime() -UFormat %s))
        } else {
            $_resubmissionDate = 0
        }

        if ($Reminder) {
            $_reminder = [int][double]::Parse((Get-Date -Date $Reminder.ToUniversalTime() -UFormat %s))
        } else {
            $_reminder = 0
        }

        if ($DueDate) {
            $_dueDate = [int][double]::Parse((Get-Date -Date $DueDate.ToUniversalTime() -UFormat %s))
        } else {
            $_dueDate = 0
        }


        $body = [ordered]@{
            companyId                  = $CompanyId
            remitterId                 = $RemitterId
            orderById                  = $OrderById
            title                      = "$($Title)"
            content                    = "$($Description)"
            extTicketId                = "$($ExternalTicketId)"
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
            dueDate                    = $_dueDate
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

        if ($pscmdlet.ShouldProcess("Ticket with title '$($Title)' on companyID '$($CompanyId)'", "New")) {
            Write-PSFMessage -Level Verbose -Message "Creating Ticket with title '$($Title)' on companyID '$($CompanyId)'" -Tag "Ticket" -Data $body

            $response = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body -Token $Token

            if($response) {
                Write-PSFMessage -Level Verbose -Message "API Response: $($response.meta.text)"

                Push-DataToCacheRunspace -MetaData $response.meta

                [TANSS.Ticket]@{
                    BaseObject = $response.content
                    Id         = $response.content.id
                }
            } else {
                Write-PSFMessage -Level Error -Message "Error creating ticket, no ticket response from API"
            }
        }
    }

    end {
    }
}