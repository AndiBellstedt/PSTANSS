function Get-TANSSProjectPhase {
    <#
    .Synopsis
        Get-TANSSProjectPhase

    .DESCRIPTION
        Get phases of a project in TANSS

    .PARAMETER ProjectID
        The ID of the poject to receive phases from

    .PARAMETER Project
        TANSS.Project object to receive phases from

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSProjectPhase -ProjectId 10

        Get phases out of project 10

    .EXAMPLE
        PS C:\> $projects | Get-TANSSTicketActivity

        Get all phases of projects in variable $tickets

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    [OutputType([TANSS.ProjectPhase])]
    Param(
        [Parameter(
            ParameterSetName = "ByProjectId",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [Alias("Id")]
        [int[]]
        $ProjectID,

        [Parameter(
            ParameterSetName = "ByProject",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.Project[]]
        $Project,

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


        if ($parameterSetName -like "ByProject") {
            $inputobjectProjectCount = ([array]$Project).Count
            Write-PSFMessage -Level System -Message "Getting IDs of $($inputobjectProjectCount) project$(if($inputobjectProjectCount -gt 1){'s'})"  -Tag "ProjectPhase", "CollectInputObjects"
            [array]$ProjectID = $Project.id
        }

        foreach ($projectIdItem in $ProjectID) {
            Write-PSFMessage -Level Verbose -Message "Working on project ID $($projectIdItem)"  -Tag "ProjectPhase", "Query"

            # build api path
            $apiPath = Format-ApiPath -Path "api/v1/projects/$projectIdItem/phases"

            # query content
            $response = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token
            Push-DataToCacheRunspace -MetaData $response.meta
            Write-PSFMessage -Level Verbose -Message "$($response.meta.text): Received $($response.meta.properties.extras.count) VacationEntitlement records in year $($Year)" -Tag "VacationEntitlement", "Query"

            # create output
            foreach ($phase in $response.content) {
                [TANSS.ProjectPhase]@{
                    BaseObject = $phase
                    Id         = $phase.id
                }
            }
        }
    }

    end {}
}
