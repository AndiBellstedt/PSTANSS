function Remove-TANSSProjectPhase {
    <#
    .Synopsis
        Remove-TANSSProjectPhase

    .DESCRIPTION
        Removes a project phase from TANSS

    .PARAMETER InputObject
        TANSS.ProjectPhase object to remove

    .PARAMETER Force
        Process the removal quietly.

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> $phase | Remove-TANSSProjectPhase

        Remove project phase in variable $phase from TANSS

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'High'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("Phase", "ProjectPhase")]
        [TANSS.ProjectPhase[]]
        $InputObject,

        [switch]
        $Force,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        $processRemoval = $false

        foreach ($projectPhase in $InputObject) {
            # Check on Force parameter, otherwise process shouldprocess
            if ($Force) {
                $processRemoval = $true
            } else {
                if ($pscmdlet.ShouldProcess("ProjectPhase Id $($projectPhase.Id) '$($projectPhase.Name)' from project '$($projectPhase.Project)' (Id $($projectPhase.ProjectId))", "Remove")) {
                    $processRemoval = $true
                }
            }

            if ($processRemoval) {
                Write-PSFMessage -Level Verbose -Message "Remove ProjectPhase Id $($projectPhase.Id) '$($projectPhase.Name)' from project '$($projectPhase.Project)' (Id $($projectPhase.ProjectId))" -Tag "ProjectPhase", "Remove"

                # Remove projectPhase
                $apiPath = Format-ApiPath -Path "api/v1/projects/phases/$($projectPhase.Id)"
                Invoke-TANSSRequest -Type DELETE -ApiPath $apiPath -Token $Token -Confirm:$false -WhatIf:$false -ErrorVariable "invokeError"

                # cache Lookup refresh
                [TANSS.Lookup]::Phases.Remove($($projectPhase.Id))
            }
        }
    }

    end {}
}
