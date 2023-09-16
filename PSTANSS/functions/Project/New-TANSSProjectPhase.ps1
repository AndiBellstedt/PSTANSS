function New-TANSSProjectPhase {
    <#
    .Synopsis
        Add a project phase into a project

    .DESCRIPTION
        Add a project phase into a project

    .PARAMETER ProjectID
        The ID of the poject where to create the specified phase

    .PARAMETER Project
        TANSS.Project object where to create the specified phase

    .PARAMETER Name
        The name of the phase

    .PARAMETER Rank
        The rank of the phase, when there are other phases in the project

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

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> New-TANSSProjectPhase -Project $project -Name "Phase X"

        Creates "Phase X" within the project in the variable $project

    .EXAMPLE
        PS C:\> $project | New-TANSSProjectPhase -Name "Phase X"

        Creates "Phase X" within the project in the variable $project

    .EXAMPLE
        PS C:\> New-TANSSProjectPhase -ProjectId $project.id -Name "Phase X", "Phase Y", "Phase Z"

        Creates 3 phases ("Phase X", "Phase Y", "Phase Z") within the project in the variable $project

        .EXAMPLE
        PS C:\> "Phase X", "Phase Y", "Phase Z" | New-TANSSProjectPhase -ProjectId $project.id

        Creates 3 phases ("Phase X", "Phase Y", "Phase Z") within the project in the variable $project

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ByProject",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([TANSS.ProjectPhase])]
    Param(
        [Parameter(
            ParameterSetName = "ByPhaseName",
            Mandatory = $true
        )]
        [Alias("Id")]
        [int]
        $ProjectID,

        [Parameter(
            ParameterSetName = "ByProject",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.Project]
        $Project,

        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [string[]]
        $Name,

        [int]
        $Rank,

        [datetime]
        $StartDate,

        [datetime]
        $EndDate,

        [bool]
        $RequiredPrePhasesComplete = $false,

        [ValidateSet("InstantBillSupportActivities", "BillClosedTicketOnly", "BillOnlyWhenAllTicketsClosed")]
        [string]
        $BillingType = "InstantBillSupportActivities",

        [ValidateSet("Default", "ReleaseSupportOfUnresolvedTickets", "LockSupportsOfUnresolvedTickets")]
        [String]
        $ClearanceMode = "Default",

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning

        $apiPath = Format-ApiPath -Path "api/v1/projects/phases"

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


        if ($parameterSetName -like "ByProject") {
            $ProjectID = $Project.id
            Write-PSFMessage -Level System -Message "Identified ID '$($ProjectID) for project $($Project.Title)"  -Tag "ProjectPhase", "CollectInputObjects"
        }


        # Create body object for api call
        foreach ($nameItem in $Name) {
            Write-PSFMessage -Level Verbose -Message "Working new phase '$($nameItem)' for project ID $($ProjectID)"  -Tag "ProjectPhase", "New"

            $phaseToCreate = [ordered]@{
                projectId               = $ProjectID
                name                    = $nameItem
                closedPrePhasesRequired = $RequiredPrePhasesComplete
                billingType             = $_billingType
                clearanceMode           = $_clearanceMode
            }

            if ($Rank) { $phaseToCreate.add("rank", $Rank) }

            if ($StartDate) {
                $_startDate = [int32][double]::Parse((Get-Date -Date $StartDate.ToUniversalTime() -UFormat %s))
                $phaseToCreate.add("startDate", $_startDate)
            }

            if ($EndDate) {
                $_endDate = [int32][double]::Parse((Get-Date -Date $EndDate.ToUniversalTime() -UFormat %s))
                $phaseToCreate.add("endDate", $_endDate)
            }


            # Create phase
            if ($pscmdlet.ShouldProcess("phase '$($nameItem)' in project id $($ProjectID)", "New")) {
                Write-PSFMessage -Level Verbose -Message "New phase '$($nameItem)' in project id $($ProjectID)" -Tag "ProjectPhase", "New"

                # invoke api call
                $response = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $phaseToCreate -Token $Token -WhatIf:$false

                Write-PSFMessage -Level Verbose -Message "$($response.meta.text): $($response.content.name) (Rank: $($response.content.rank), Id: $($response.content.id))" -Tag "ProjectPhase", "New", "CreatedSuccessfully"

                # create output
                [TANSS.ProjectPhase]@{
                    BaseObject = $response.content
                    Id         = $response.content.id
                }

                # cache Lookup refresh
                [TANSS.Lookup]::Phases[$response.content.id] = $response.content.name
            }
        }
    }

    end {}
}
