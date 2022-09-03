function Format-ApiPath {
    <#
    .Synopsis
        Format-ApiPath

    .DESCRIPTION
        Ensure the right format and the existense of api prefix in the given path

    .PARAMETER Path
        Path to format

    .EXAMPLE
        Format-ApiPath -Path $ApiPath

        Example

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
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    Write-PSFMessage -Level System -Message "Formatting API path '$($Path)'"

    $apiPrefix = Get-PSFConfigValue -FullName 'PSTANSS.API.RestPathPrefix' -Fallback ""

    # remove no more need slashes
    $apiPath = $Path.Trim('/')

    # check on API path prefix
    if(-not $ApiPath.StartsWith($apiPrefix)) {
        $ApiPath = $apiPrefix + $ApiPath
        Write-PSFMessage -Level System -Message "Add API prefix, finished formatting path to '$($ApiPath)'"
    } else {
        Write-PSFMessage -Level System -Message "Prefix API path already present, finished formatting"
    }

    # Output Result
    $ApiPath
}
