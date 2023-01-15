function Assert-CacheRunspaceRunning {
    <#
    .Synopsis
        Assert-CacheRunspaceRunning

    .DESCRIPTION
        Check cache validation runspace on status

    .EXAMPLE
        PS C:\> Assert-CacheRunspaceRunning

        Check cache validation runspace on status

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
    )

    Write-PSFMessage -Level Debug -Message "Check cache validationRunspace"

    if ([TANSS.Cache]::StopValidationRunspace -eq $true) {
        Write-PSFMessage -Level Debug -Message "ValidationRunspace is stopped. Going to start the runspace again"

        # force to stop the runspace
        [TANSS.Cache]::StopValidationRunspace = $true
        Get-PSFRunspace -Name "TANSS.LookupValidation" | Stop-PSFRunspace

        # Restart the runspace
        try {
            [TANSS.Cache]::StopValidationRunspace = $false
            Start-PSFRunspace -Name "TANSS.LookupValidation" -ErrorAction Stop -ErrorVariable invokeError
        } catch {
            Stop-PSFFunction -Message "Error Starting ValidationRunspace. Unknown module behaviour. Please restart your powershell console!" -EnableException $true -Exception $invokeError -Tag "RunSpace"
            throw $invokeError
        }
    }

}
