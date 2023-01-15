function Format-ApiPath {
    <#
    .Synopsis
        Format-ApiPath

    .DESCRIPTION
        Ensure the right format and the existense of api prefix in the given path

    .PARAMETER Path
        Path to format

    .PARAMETER QueryParameter
        A hashtable for all the parameters to the api route

    .EXAMPLE
        Format-ApiPath -Path $ApiPath

        Api path data from variable $ApiPath will be tested and formatted.

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
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [hashtable]
        $QueryParameter
    )

    # Start Function
    Write-PSFMessage -Level System -Message "Formatting API path '$($Path)'"

    # receive module cental configuration for prefix on api path (default is 'backend/')
    $apiPrefix = Get-PSFConfigValue -FullName 'PSTANSS.API.RestPathPrefix' -Fallback ""

    # remove no more need slashes
    $apiPath = $Path.Trim('/')


    # check on API path prefix
    if (-not $ApiPath.StartsWith($apiPrefix)) {
        $ApiPath = $apiPrefix + $ApiPath
        Write-PSFMessage -Level Debug -Message "Add API prefix, formatting path to '$($ApiPath)'"
    } else {
        Write-PSFMessage -Level Debug -Message "Prefix API path already present"
    }


    # If specified, process hashtable QueryParameters to valid parameters into uri
    if ($MyInvocation.BoundParameters['QueryParameter'] -and $QueryParameter) {
        Write-PSFMessage -Level Debug -Message "Add query parameters '$([string]::Join("' ,'", $QueryParameter.Keys))'"

        $apiPath = "$($apiPath)?"
        $i = 0

        foreach ($key in $QueryParameter.Keys) {
            if ($i -gt 0) {
                $apiPath = "$($apiPath)&"
            }

            if ("System.Array" -in ($QueryParameter[$Key]).psobject.TypeNames) {
                $parts = $QueryParameter[$Key] | ForEach-Object { "$($key)=$($_)" }
                $apiPath = "$($apiPath)$([string]::Join("&", $parts))"
            } else {
                $apiPath = "$($apiPath)$($key)=$($QueryParameter[$Key])"
            }

            $i++
        }
    }


    # Output Result
    $ApiPath
}
