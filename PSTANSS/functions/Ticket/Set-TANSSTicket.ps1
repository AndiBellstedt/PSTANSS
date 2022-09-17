function Set-TANSSTicket {
    <#
    .Synopsis
        Set-TANSSTicket

    .DESCRIPTION
        Modify a ticket in TANSS

    .PARAMETER Token
        The TANSS.Connection token

    .PARAMETER PassThru
        Outputs the token to the console, even when the register switch is set

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        Set-TANSSTicket -ID 10 -NewTitle "New ticket title"

        Update title to "New ticket title" of ticket with ticketID 10

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'UserFriendly-ByInputObject',
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        # TANSS Ticket object to modify
        [Parameter(
            ParameterSetName = "ApiNative-ByInputObject",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = "UserFriendly-ByInputObject",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [TANSS.Ticket[]]
        $InputObject,

        # Id of the ticket to modify
        [Parameter(
            ParameterSetName = "ApiNative-ById",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = "UserFriendly-ById",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("TicketId", "Ticket")]
        [int[]]
        $Id,

        # Company id of the ticket. Name is stored in the "linked entities" - "companies". Can only be set if the user has access to the company
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [int]
        $CompanyId,

        # Company name where the ticket should create for. Can only be set if the user has access to the company
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [String]
        $Company,

        # If the ticket has a remitter, the id goes here. Name is stored in the "linked entities" - "employees"
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [Alias('ClientId')]
        [int]
        $RemitterId,

        # If the ticket has a remitter/client, the name of the client
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [String]
        $Client,

        # gives infos about how the remitter gave the order. Infos are stored in the "linked entities" - "orderBys"
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [int]
        $OrderById,

        # gives infos about how the Client gave the order.
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [string]
        $OrderBy,

        # The title / subject of the ticket
        [Alias('Title', "NewName")]
        [string]
        $NewTitle,

        # The content / description of the ticket
        [Alias('content')]
        [string]
        $Description,

        # External ticket id (optional)
        [Alias('extTicketId')]
        [string]
        $ExternalTicketId,

        # id of employee which ticket is assigned to. Name is stored in "linked entities" - "employees"
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [Alias('assignedToEmployeeId')]
        [int]
        $EmployeeIdAssigned,

        # Name of the employee the ticket is assigned to
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [String]
        $EmployeeAssigned,

        # id of department the ticket is assigned to. Name is stored in "linked entities" - "departments"
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [Alias('assignedToDepartmentId')]
        [int]
        $DepartmentIdAssigned,

        # Name of the department the ticket is assigned to
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [String]
        $Department,

        # id of the ticket state. Name is give in "linked entities" - "ticketStates"
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [int]
        $StatusId,

        # The name of the ticket status
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [String]
        $Status,

        # id of the ticket type. Name is give in "linked entities" - "ticketTypes"
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [int]
        $TypeId,

        # The name of the ticket type
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [String]
        $Type,

        # if ticket is assigned to device / employee, linktype is given here
        [Alias('LinkTypeId')]
        [int]
        $AssignmentId,

        # If ticket has a deadline, the date is given here
        [Alias('deadlineDate')]
        [datetime]
        $Deadline,

        # if ticket is a sub-ticket of a project, the id of the project goes here. Name of the project is in the "linked entities" - "tickets"
        [int]
        $ProjectId,

        # if the ticket is assignet to a project phase. The name of the phase is stored in the "linked entities" - "phases"
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [Int]
        $PhaseId,

        # if the ticket is assignet to a project phase, the name of the phase
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [String]
        $Phase,

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
        [Parameter(ParameterSetName = "ApiNative-ByInputObject")]
        [Parameter(ParameterSetName = "ApiNative-ById")]
        [ValidateNotNullOrEmpty]
        [int]
        $LocalTicketAdminEmployeeId,

        # if the ticket is assigned to a local ticket admin, this represents the name of the employee (local ticket admin) who is assigned for this ticket
        [Parameter(ParameterSetName = "UserFriendly-ByInputObject")]
        [Parameter(ParameterSetName = "UserFriendly-ById")]
        [ValidateNotNullOrEmpty]
        [String]
        $EmployeeTicketAdmin,

        # Sets the order number
        [string]
        $OrderNumber,

        # If the ticket has a reminder set, the timestamp is returned here
        [datetime]
        $Reminder,

        [switch]
        $PassThru,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning

        if ($EmployeeTicketAdmin) {
            $LocalTicketAdminEmployeeId = ConvertFrom-NameCache -Name $EmployeeTicketAdmin -Type "Employees"
            if (-not $LocalTicketAdminEmployeeId) {
                Write-PSFMessage -Level Warning -Message "No Id for employee '$($EmployeeTicketAdmin)' found, ticket will not be modified on TicketAdminEmployee value"
                #todo implement API call for employee
            }
        }

        if ($EmployeeAssigned) {
            $EmployeeIdAssigned = ConvertFrom-NameCache -Name $EmployeeAssigned -Type "Employees"
            if (-not $EmployeeIdAssigned) {
                Write-PSFMessage -Level Warning -Message "No Id for employee '$($EmployeeAssigned)' found, ticket will not be modified on EmployeeIdAssigned value"
                #todo implement API call for employee
            }
        }

        if ($Client) {
            $RemitterId = ConvertFrom-NameCache -Name $Client -Type "Employees"
            if (-not $RemitterId) {
                Write-PSFMessage -Level Warning -Message "No Id for client '$($Client)' found, ticket will not be modified on RemitterId value"
                #todo implement API call for employee
            }
        }

        if ($Phase) {
            $PhaseId = ConvertFrom-NameCache -Name $Phase -Type "Phases"
            if (-not $PhaseId) {
                Write-PSFMessage -Level Warning -Message "No Id for phase '$($Phase)' found, ticket will not be modified on Phase value"
            }
        }

        if ($Type) {
            $TypeId = ConvertFrom-NameCache -Name $Type -Type "TicketTypes"
            if (-not $TypeId) {
                Write-PSFMessage -Level Warning -Message "No Id for ticket type '$($Type)' found, ticket will not be modified on TicketType value"
            }
        }

        if ($OrderBy) {
            $OrderById = ConvertFrom-NameCache -Name $OrderBy -Type "OrderBys"
            if (-not $OrderById) {
                Write-PSFMessage -Level Warning -Message "No Id for OrderBy type '$($OrderBy)' found, ticket will not be modified on OrderBy value"
            }
        }

        if ($Status) {
            $StatusId = ConvertFrom-NameCache -Name $Status -Type "TicketStates"
            if (-not $StatusId) {
                Write-PSFMessage -Level Warning -Message "No Id for ticket state '$($Status)' found, ticket will not be modified on TicketStatus value"
            }
        }

        if ($Department) {
            $DepartmentIdAssigned = ConvertFrom-NameCache -Name $Department -Type "Departments"
            if (-not $DepartmentIdAssigned) {
                Write-PSFMessage -Level Warning -Message "No Id for department '$($Department)' found, ticket will not be modified on departmentIdAssigned value"
            }
        }

        if ($Company) {
            $CompanyId = ConvertFrom-NameCache -Name $Company -Type "Companies"
            if (-not $CompanyId) {
                Write-PSFMessage -Level Warning -Message "No Id for company '$($Company)' found, ticket will not be modified on CompanyId"
            }
        }


        if ($Deadline) {
            $_deadlineDate = [int][double]::Parse((Get-Date -Date $Deadline -UFormat %s))
        } else {
            $_deadlineDate = 0
        }

        if ($DueDate) {
            $_dueDate = [int][double]::Parse((Get-Date -Date $DueDate -UFormat %s))
        } else {
            $_dueDate = 0
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
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        if ($parameterSetName -like "*ById*") {
            $InputObject = foreach ($idItem in $Id) {
                Get-TANSSTicket -Id $idItem -ErrorAction Continue
            }
        }


        foreach ($ticket in $InputObject) {
            Write-PSFMessage -Level Verbose -Message "Working on TicketID $($ticket.Id) '$($ticket.Title)'"
            $apiPath = Format-ApiPath -Path "api/v1/tickets/$($ticket.Id)"

            $body = [ordered]@{
                "companyId"                  = (.{if ($CompanyId) { $CompanyId } else { $ticket.BaseObject.companyId }})
                "remitterId"                 = (.{if ($RemitterId) { $RemitterId } else { $ticket.BaseObject.remitterId }})
                "title"                      = (.{if ($NewTitle) { "$($NewTitle)" } else { $ticket.BaseObject.title }})
                "content"                    = (.{if ($Description) { "$($Description)" } else { $ticket.BaseObject.content }})
                "extTicketId"                = (.{if ($ExternalTicketId) { "$($ExternalTicketId)" } else { $ticket.BaseObject.extTicketId }})
                "assignedToEmployeeId"       = (.{if ($EmployeeIdAssigned) { $EmployeeIdAssigned } else { $ticket.BaseObject.assignedToEmployeeId }})
                "assignedToDepartmentId"     = (.{if ($DepartmentIdAssigned) { $DepartmentIdAssigned } else { $ticket.BaseObject.assignedToDepartmentId }})
                "statusId"                   = (.{if ($StatusId) { $StatusId } else { $ticket.BaseObject.statusId }})
                "typeId"                     = (.{if ($TypeId) { $TypeId } else { $ticket.BaseObject.typeId }})
                "linkTypeId"                 = (.{if ($AssignmentId) { $AssignmentId } else { $ticket.BaseObject.linkTypeId }})
                "linkId"                     = $ticket.BaseObject.linkId
                "deadlineDate"               = (.{if ($_deadlineDate) { $_deadlineDate } else { $ticket.BaseObject.deadlineDate }})
                "project"                    = $ticket.BaseObject.project.ToString()
                "projectId"                  = (.{if ($ProjectId) { $ProjectId } else { $ticket.BaseObject.projectId }})
                "repair"                     = (.{if ($IsRepair) { $IsRepair } else { $ticket.BaseObject.repair }})
                "dueDate"                    = (.{if ($_dueDate) { $_dueDate } else { $ticket.BaseObject.dueDate }})
                "attention"                  = (.{if ($Attention) { $Attention } else { $ticket.BaseObject.attention }})
                "orderById"                  = (.{if ($OrderById) { $OrderById } else { $ticket.BaseObject.orderById }})
                "installationFee"            = (.{if ($InstallationFee) { $InstallationFee } else { $ticket.BaseObject.installationFee }})
                "installationFeeDriveMode"   = (.{if ($InstallationFeeDriveMode) { $InstallationFeeDriveMode } else { "None" }})
                "installationFeeAmount"      = (.{if ($InstallationFeeAmount) { $InstallationFeeAmount } else { $ticket.BaseObject.installationFeeAmount }})
                "separateBilling"            = (.{if ($SeparateBilling) { $SeparateBilling.ToString() } else { $ticket.BaseObject.separateBilling }})
                "serviceCapAmount"           = (.{if ($ServiceCapAmount) { $ServiceCapAmount } else { $ticket.BaseObject.serviceCapAmount }})
                "relationshipLinkTypeId"     = (.{if ($RelationshipLinkTypeId) { $RelationshipLinkTypeId } else { $ticket.BaseObject.orderById }})
                "relationshipLinkId"         = (.{if ($RelationshipLinkId) { $RelationshipLinkId } else { $ticket.BaseObject.relationshipLinkId }})
                "resubmissionDate"           = (.{if ($_resubmissionDate) { $_resubmissionDate } else { $ticket.BaseObject.resubmissionDate }})
                "estimatedMinutes"           = (.{if ($EstimatedMinutes) { $EstimatedMinutes } else { $ticket.BaseObject.estimatedMinutes }})
                "localTicketAdminFlag"       = (.{if ($LocalTicketAdminFlag) { $LocalTicketAdminFlag } else { $ticket.BaseObject.localTicketAdminFlag }})
                "localTicketAdminEmployeeId" = (.{if ($LocalTicketAdminEmployeeId) { $LocalTicketAdminEmployeeId } else { $ticket.BaseObject.localTicketAdminEmployeeId }})
                "phaseId"                    = (.{if ($PhaseId) { $PhaseId } else { $ticket.BaseObject.phaseId }})
                "resubmissionText"           = (.{if ($ResubmissionText) { "$($ResubmissionText)" } else { $ticket.BaseObject.resubmissionText }})
                "orderNumber"                = (.{if ($OrderNumber) { "$($OrderNumber)" } else { $ticket.BaseObject.orderNumber }})
                "reminder"                   = (.{if ($_reminder) { $_reminder } else { $ticket.BaseObject.reminder }})
            }

            if ($pscmdlet.ShouldProcess("TicketID $($ticket.Id) with $(if($NewTitle){"new "})title '$(if($NewTitle){$NewTitle}else{$ticket.Title})'", "Update")) {
                Write-PSFMessage -Level Verbose -Message "Updating TicketID $($ticket.Id) with $(if($NewTitle){"new "})title '$(if($NewTitle){$NewTitle}else{$ticket.Title})'" -Tag "Ticket" -Data $body

                $response = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $body -Token $Token

                if ($response) {
                    Write-PSFMessage -Level Verbose -Message "API Response: $($response.meta.text)"

                    Push-DataToCacheRunspace -MetaData $response

                    if($PassThru) {
                        foreach ($content in $response.content) {
                            [TANSS.Ticket]@{
                                BaseObject = $content
                                Id         = $content.id
                            }
                        }
                    }
                } else {
                    Write-PSFMessage -Level Error -Message "Error updating ticketID '$($ticket.Id)', no ticket response from API"
                }
            }
        }
    }

    end {
    }
}