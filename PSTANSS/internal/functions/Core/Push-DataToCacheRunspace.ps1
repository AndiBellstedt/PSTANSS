function Push-DataToCacheRunspace {
    <#
    .Synopsis
        Push-DataToCacheRunspace

    .DESCRIPTION
        Push meta information to runspace cache

    .EXAMPLE
        Push-DataToCacheRunspace -MetaData $response.meta

        Push meta information to runspace cache

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Alias("Meta", "Data")]
        $MetaData
    )

    Write-PSFMessage -Level Debug -Message "Pushing data to cache validationRunspace"

    [TANSS.Cache]::Data.Add((New-Guid), $MetaData)

}
