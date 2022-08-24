function Register-TANSSAccessToken {
    <#
    .Synopsis
       Register-TANSSAccessToken

    .DESCRIPTION
       Register the AccessToken as default connection setting for TANSS

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .EXAMPLE
       Register-TANSSAccessToken

       Retrieve the registered LoginToken for TANSS

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [psobject]
        $Token
    )

    begin {}

    process {

        if ($pscmdlet.ShouldProcess("AccessToken for $($Token.UserName) on '$($Token.Server)'", "Register")) {
            Write-PSFMessage -Level Verbose -Message "Register AccessToken for $($Token.UserName) on '$($Token.Server)'" -Tag "AccessToken"

            $script:TANSSToken = $Token
        }
    }

    end {}
}
