function Set-TANSSProjectPhase {
    <#
    .Synopsis
        Modify a phase inside project

    .DESCRIPTION
        Modify a phase inside project

    .PARAMETER Phase
        TANSS.ProjectPhase object to set

    .PARAMETER PhaseID
        The ID of the poject phase to set

    .PARAMETER Project
        TANSS.Project where to modify a phase

    .PARAMETER PhaseName
        The name of the phase to modify

    .PARAMETER Name
        The (new) name for the phase to set

    .PARAMETER Rank
        The order of the phase in relation to other project phases

    .PARAMETER StartDate
        The (planned) starting date of the phase

    .PARAMETER EndDate
        The (planned) ending date of the phase

    .PARAMETER RequiredPrePhasesComplete
        Indicates that all tickets in the previous phase has to be finished to open this phase

        Default: $false

    .PARAMETER BillingType
        Set the behavour how to bill tickets.
        Values are available via TabCompletion.
        Possible are:
            "InstantBillSupportActivities" = Support activities of sub-tickets are immediately billable
            "BillClosedTicketOnly" = Only Support activities of completed sub-tickets are billable
            "BillOnlyWhenAllTicketsClosed" = Phase may only be billed when all sub-tickets have been completed

        Default: "InstantBillSupportActivities"

    .PARAMETER ClearanceMode
        Set the behavour how support activities in tickets for the phase are treated.
        Values are available via TabCompletion.
        Possible are:
            "Default" = Setting from TANSS application base preferences is used
            "ReleaseSupportOfUnresolvedTickets" = support activities in open tickets can be released
            "LockSupportsOfUnresolvedTickets" = support activities in open tickets can not be released

        Default: "Default"

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER PassThru
        Outputs the result to the console

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Set-TANSSProjectPhase -PhaseID $phase.Id -Name "NewPhaseName X"

        Rename the phase from variable $phase to "NewPhaseName X"
        $Phase has to be filled with a

    .EXAMPLE
        PS C:\> $phase | Set-TANSSProjectPhase -Name "NewPhaseName X"

        Rename the phase from variable $phase to "NewPhaseName X"
        $Phase has to be filled with a

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ByPhase",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([TANSS.ProjectPhase])]
    Param(
        [Parameter(
            ParameterSetName = "ByPhaseId",
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [Alias("Id")]
        [int]
        $PhaseID,

        [Parameter(
            ParameterSetName = "ByPhase",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.ProjectPhase]
        $Phase,

        [Parameter(
            ParameterSetName = "ByProject",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.Ticket]
        $Project,

        [Parameter(
            ParameterSetName = "ByProject",
            Mandatory = $true
        )]
        [string]
        $PhaseName,

        [ValidateNotNullOrEmpty()]
        [Alias("NewName")]
        [string]
        $Name,

        [ValidateNotNullOrEmpty()]
        [int]
        $Rank,

        [ValidateNotNullOrEmpty()]
        [datetime]
        $StartDate,

        [ValidateNotNullOrEmpty()]
        [datetime]
        $EndDate,

        [bool]
        $RequiredPrePhasesComplete,

        [ValidateSet("InstantBillSupportActivities", "BillClosedTicketOnly", "BillOnlyWhenAllTicketsClosed")]
        [string]
        $BillingType,

        [ValidateSet("Default", "ReleaseSupportOfUnresolvedTickets", "LockSupportsOfUnresolvedTickets")]
        [String]
        $ClearanceMode,

        [switch]
        $PassThru,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning

        # Translate BillingType into api value
        if ($BillingType) {
            switch ($BillingType) {
                "InstantBillSupportActivities" { $_billingType = "DEFAULT" }
                "BillClosedTicketOnly" { $_billingType = "TICKET_MUST_BE_CLOSED" }
                "BillOnlyWhenAllTicketsClosed" { $_billingType = "ALL_TICKETS_MUST_BE_CLOSED" }
                Default {
                    Stop-PSFFunction -Message "Unhandeled Value in BillingType. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
                }
            }
        }

        # Translate BillingType into api value
        if ($ClearanceMode) {
            switch ($ClearanceMode) {
                "Default" { $_clearanceMode = "DEFAULT" }
                "ReleaseSupportOfUnresolvedTickets" { $_clearanceMode = "DONT_CLEAR_SUPPORTS" }
                "LockSupportsOfUnresolvedTickets" { $_clearanceMode = "MAY_CLEAR_SUPPORTS" }
                Default {
                    Stop-PSFFunction -Message "Unhandeled Value in ClearanceMode. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
                }
            }
        }
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"


        # ParameterSet handling
        if ($parameterSetName -like "ByPhase") {
            $PhaseID = $Phase.id
            $projectID = $Phase.ProjectId
            Write-PSFMessage -Level System -Message "Identified ID '$($PhaseID) for project phase $($Phase.Name) within project '$($Phase.Project)' (Id: $($projectID))" -Tag "ProjectPhase", "CollectInputObjects"
        }

        if ($parameterSetName -like "ByProject") {
            $projectID = $Project.Id
            $Phase = Get-TANSSProjectPhase -ProjectID $Project.Id -Token $Token | Where-Object Name -Like $PhaseName
            if (-not $Phase) {
                Write-PSFMessage -Level Error -Message "Phase '$($PhaseName)' not found in project '$($Project.Title)' (Id: $($Project.Id))" -Tag "ProjectPhase", "CollectInputObjects" -Data @{"Project" = $Project }
                continue
            }
            $PhaseID = $Phase.Id
            Write-PSFMessage -Level System -Message "Identified ID '$($PhaseID) for project phase $($Phase.Name) within project $($Phase.Project)"  -Tag "ProjectPhase", "CollectInputObjects"
        }


        # Create body object for api call
        Write-PSFMessage -Level Verbose -Message "Going to set phase ID $($PhaseID)"  -Tag "ProjectPhase", "Set"

        $paramFormatApiPath = @{
            "Path" = "api/v1/projects/phases/$($PhaseID)"
        }
        $paramFormatApiPathQueryParameter = @{}

        $phaseToSet = [ordered]@{
            Id = $PhaseID
            #projectId = $ProjectID
        }
        if ($ProjectID) { $phaseToSet.add("projectId", $ProjectID) }
        if ($Name) { $phaseToSet.add("name", $Name) }
        if ($RequiredPrePhasesComplete) { $phaseToSet.add("closedPrePhasesRequired", $RequiredPrePhasesComplete) }
        if ($BillingType) { $phaseToSet.add("billingType", $_billingType) }
        if ($ClearanceMode) { $phaseToSet.add("clearanceMode", $_clearanceMode) }
        if ($Rank) { $phaseToSet.add("rank", $Rank) }
        if ($StartDate) {
            $_startDate = [int32][double]::Parse((Get-Date -Date $StartDate.ToUniversalTime() -UFormat %s))
            $phaseToSet.add("startDate", $_startDate)

            $paramFormatApiPathQueryParameter["adjustStart"] = $true
            $paramFormatApiPathQueryParameter["adjustEnd"] = $true
        }
        if ($EndDate) {
            $_endDate = [int32][double]::Parse((Get-Date -Date $EndDate.ToUniversalTime() -UFormat %s))
            $phaseToSet.add("endDate", $_endDate)

            $paramFormatApiPathQueryParameter["adjustStart"] = $true
            $paramFormatApiPathQueryParameter["adjustEnd"] = $true
        }

        if ($paramFormatApiPathQueryParameter["adjustStart"] -or $paramFormatApiPathQueryParameter["adjustEnd"]) {
            $paramFormatApiPath.Add("QueryParameter", $paramFormatApiPathQueryParameter)
        }

        $apiPath = Format-ApiPath @paramFormatApiPath

        # Create phase
        $response = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $phaseToSet -Token $Token -WhatIf:$false
        Write-PSFMessage -Level Verbose -Message "$($response.meta.text): $($response.content.adjustedPhases.name) (Rank: $($response.content.adjustedPhases.rank), Id: $($response.content.adjustedPhases.id))" -Tag "ProjectPhase", "Set", "Modify"


        # create output
        i($PassThru) {
            foreach($_phase in $response.content.adjustedPhases) {
                # object
                [TANSS.ProjectPhase]@{
                    BaseObject = $_phase
                    Id         = $_phase.id
                }

                # cache Lookup refresh
                [TANSS.Lookup]::Phases[$_phase.id] = $_phase.name
            }
        }
    }

    end {
        $null = Get-TANSSProject -Token $Token
    }
}
