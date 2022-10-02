Function ConvertFrom-UnixEpochTime {
    <#
    .SYNOPSIS
        Converts UNIX Epoch Time to DateTime object

    .DESCRIPTION
        Converts UNIX Epoch Time to DateTime object

    .PARAMETER EpochTime
        The time value to convert

    .PARAMETER UTC
        convert the given Epoch without following the lcoal timezone

    .EXAMPLE
        PS C:\> ConvertFrom-UnixEpochTime -EpochTime "1641769200"

        Converts the content from variable $TokenText to an object
    #>
    param(
        # Parameter help description
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [int[]]
        $EpochTime,

        [switch]
        $UTC
    )

    Process {

        foreach ($item in $EpochTime) {
            if ($UTC) {
                ([datetime]'1/1/1970').AddSeconds($item)
            } else {
                [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($item))
            }
        }

    }
}
