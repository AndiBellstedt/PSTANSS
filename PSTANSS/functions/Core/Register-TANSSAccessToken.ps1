function Register-TANSSAccessToken {
    <#
    .Synopsis
        Register-TANSSAccessToken

    .DESCRIPTION
        Register the AccessToken as default connection setting for TANSS

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Register-TANSSAccessToken -Token $Token

        Register the LoginToken from variable $Token as a default connection for TANSS

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [TANSS.Connection]
        $Token
    )

    begin {}

    process {

        if ($pscmdlet.ShouldProcess("AccessToken for $($Token.UserName) on '$($Token.Server)'", "Register")) {
            Write-PSFMessage -Level Verbose -Message "Registering AccessToken for $($Token.UserName) on '$($Token.Server)' valid until '$($Token.TimeStampExpires)'" -Tag "AccessToken"

            $script:TANSSToken = $Token
        }
    }

    end {}
}
