function Invoke-TANSSTokenCheck {
    <#
    .Synopsis
        Test a TANSS connection- oder service-token

    .DESCRIPTION
        Tests validity for a TANSS.Connection object

    .PARAMETER Token
        TANSS.Connection Token object to check on

    .PARAMETER NoRefresh
        Indicates that the function will not try to update the specified token


    .PARAMETER DoNotRegisterConnection

    .PARAMETER PassThru

    .EXAMPLE
        PS C:\> Invoke-TANSSTokenCheck -Token $Token

        Test the TANSS.Connection object from variable $Token for validity

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [TANSS.Connection]
        $Token,

        [Parameter(ParameterSetName = "NoRefresh")]
        [switch]
        $NoRefresh,

        [Parameter(ParameterSetName = "Default")]
        [switch]
        $DoNotRegisterConnection,

        [switch]
        $PassThru
    )

    begin {
        $registeredToken = Get-TANSSRegisteredAccessToken
    }

    process {
        # General validity check
        if (-not $Token.IsValid) {
            Stop-PSFFunction -Message "$($Token.EmployeeType) token for '$($Token.UserName)' on $($Token.Server) is not valid" -Tag "AccessToken", "InvalidToken" -EnableException $true -PSCmdlet $pscmdlet
        }

        # Lifetime check
        if ($Token.PercentRemaining -lt 5) {
            Write-PSFMessage -Level Warning -Message "$($Token.EmployeeType) token for '$($Token.UserName)' on $($Token.Server) is about to expire in $($Token.TimeRemaining.Minutes) min" -Tag "AccessToken", "InvalidToken"

            if ((-not $NoRefresh) -and $Token.RefreshToken) {
                Write-PSFMessage -Level Verbose -Message "Going to try a token refresh" -Tag "AccessToken"

                # Compile parameters for Token refresh
                $paramUpdateTANSSAccessToken = @{
                    "Token"          = $Token
                    "NoCacheRefresh" = $true
                    "PassThru"       = $true
                }
                if ((([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($registeredToken.AccessToken))) -notlike [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token.AccessToken))) -or $DoNotRegisterConnection) {
                    $paramUpdateTANSSAccessToken.add("DoNotRegisterConnection", $false)
                } else {
                    $paramUpdateTANSSAccessToken.add("DoNotRegisterConnection", $true)
                }

                $newToken = Update-TANSSAccessToken @paramUpdateTANSSAccessToken

                # Output result
                if ($PassThru) {
                    $newToken
                }
            } else {
                Write-PSFMessage -Level Important -Message "Please aquire a new token as soon as possible" -Tag "AccessToken", "NoAccessTokenRefresh"
            }
        }

        # Output if
        if(-not $newToken -and $PassThru) {
            $Token
        }
    }

    end {}
}
