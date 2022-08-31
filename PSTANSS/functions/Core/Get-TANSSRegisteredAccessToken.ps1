function Get-TANSSRegisteredAccessToken {
    <#
    .Synopsis
        Get-TANSSRegisteredAccessToken

    .DESCRIPTION
        Retrieve the registered LoginToken for default TANSS connection

    .EXAMPLE
        Get-TANSSRegisteredAccessToken

        Retrieve the registered LoginToken for TANSS

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

    begin {}

    process {
        Write-PSFMessage -Level Verbose -Message "Retrieving the registered LoginToken for '$($script:TANSSToken.UserName)' on '$($script:TANSSToken.Server)'" -Tag "AccessToken"
        $script:TANSSToken
    }

    end {}
}
