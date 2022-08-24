function Get-TANSSRegisteredAccessToken {
    <#
    .Synopsis
       Get-TANSSRegisteredAccessToken

    .DESCRIPTION
       Retrieve the registered LoginToken for TANSS

    .EXAMPLE
       Get-TANSSRegisteredAccessToken

       Retrieve the registered LoginToken for TANSS

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
    )

    begin {}

    process {
        $script:TANSSToken
    }

    end {}
}
