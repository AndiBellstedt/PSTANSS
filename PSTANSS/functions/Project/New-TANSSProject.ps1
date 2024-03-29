﻿function New-TANSSProject {
    <#
    .Synopsis
        New-TANSSProject

    .DESCRIPTION
        Creates a project in TANSS, that can contain multiple tickets

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> New-TANSSProject -Title "A new project"

        Create a project with title "A new project"

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidMultipleTypeAttributes", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
    [CmdletBinding(
        DefaultParameterSetName = "Userfriendly",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([TANSS.Ticket])]
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
        [string]
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
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('New-TANSSTicket', [System.Management.Automation.CommandTypes]::Function)
            $scriptCmd = {& $wrappedCmd -IsProject $true @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline()
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}