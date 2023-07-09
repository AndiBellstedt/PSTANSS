function Get-TANSSProject {
    <#
    .Synopsis
        Get-TANSSProject

    .DESCRIPTION
        Get all projects from TANSS

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSProject

        Get all projects from TANSS

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidMultipleTypeAttributes", "")]
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    [OutputType([TANSS.Project])]
    param (
        [TANSS.Connection]
        $Token
    )
    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Get-TANSSTicket', [System.Management.Automation.CommandTypes]::Function)
            $scriptCmd = {& $wrappedCmd -Project @PSBoundParameters }
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