function Update-TANSSAccessToken {
    <#
    .Synopsis
        Update-TANSSAccessToken

    .DESCRIPTION
        Updates the AccessToken from a refreshToken for TANSS connection
        By defaault, the new Access is registered to as default connection

    .PARAMETER DoNotRegisterConnection
        Do not register the connection as default connection

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .PARAMETER PassThru
        Outputs the new token to the console

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        Update-TANSSAccessToken

        Updates the AccessToken from the default connection and register it as new
        AccessToken on default Connection

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [TANSS.Connection]
        $Token,

        [Alias('NoRegistration')]
        [Switch]
        $DoNotRegisterConnection,

        [switch]
        $PassThru
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        if ($Token.RefreshToken) {
            $refreshTokenInfo = ConvertFrom-JWTtoken -TokenText ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token.RefreshToken))).split(" ")[1]
        } else {
            Stop-PSFFunction -Message "Invalid Token specified. No refreshToken found" -Tag "Connection", "Authentication"
            throw
        }

        Write-PSFMessage -Level Verbose -Message "Checking RefreshToken from TANSS.Connection of $($Token.UserName) on '$($Token.Server)'" -Tag "AccessToken", "Connection", "Authentication"
        if ( (Get-Date) -ge $refreshTokenInfo.exp ) {
            Stop-PSFFunction -Message "RefreshToken expired. Unable to refresh with current token. Please use Connect-TANSS to login again" -Tag "Connection", "Authentication"
            return
        }

        if ($pscmdlet.ShouldProcess("AccessToken from TANSS.Connection of $($Token.UserName) on '$($Token.Server)' with RefreshToken valid until '$($refreshTokenInfo.exp)'", "Update")) {
            $apiPath = Format-ApiPath -Path "api/v1/tickets/own"

            Write-PSFMessage -Level Verbose -Message "Updating AccessToken from TANSS.Connection of $($Token.UserName) on '$($Token.Server)' with RefreshToken valid until '$($refreshTokenInfo.exp)'" -Tag "AccessToken"
            $param = @{
                "Uri"           = "$($Token.Server)/$($ApiPath)"
                "Headers"       = @{
                    "refreshToken" = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token.RefreshToken))
                }
                "Verbose"       = $false
                "Debug"         = $false
                "ErrorAction"   = "Stop"
                "ErrorVariable" = "invokeError"
            }
            try {
                $response = Invoke-RestMethod @param
            } catch {
                Stop-PSFFunction -Message "Error invoking rest call on service '$($Token.Server)'. $($invokeError)" -Tag "Connection", "Authentication"
                throw
            }

            if ($response.meta.text -notlike "Welcome, your ApiToken is 4 hours valid.") {
                Stop-PSFFunction -Message "$($response.meta.text) to service '$($Token.Server)'. Apperantly, refreshToken is not valid" -Tag "Connection", "Authentication"
                throw
            }

            if (-not $response.content.apiKey) {
                Stop-PSFFunction -Message "Something went wrong on authenticating user $($Token.UserName). No apiKey found in response. Unable to refresh token from connection '$($Token.Server)'" -Tag "Connection", "Authentication"
                throw
            }

            Write-PSFMessage -Level System -Message "Creating TANSS.Connection from refreshed AccessToken" -Tag "Connection"
            $token = [TANSS.Connection]@{
                Server            = $Token.Server
                UserName          = $Token.UserName
                EmployeeId        = $response.content.employeeId
                EmployeeType      = $response.content.employeeType
                AccessToken       = ($response.content.apiKey | ConvertTo-SecureString -AsPlainText -Force)
                RefreshToken      = ($response.content.refresh | ConvertTo-SecureString -AsPlainText -Force)
                Message           = $response.meta.text
                TimeStampCreated  = $Token.TimeStampCreated
                TimeStampExpires  = ([datetime]'1/1/1970').AddSeconds($response.content.expire)
                TimeStampModified = Get-Date
            }

            if (-not $DoNotRegisterConnection) {
                # Make the connection the default connection for further commands
                Write-PSFMessage -Level Significant -Message "Updating AccessToken for service '($($token.Server))' as '$($token.UserName)' and register it as default connection" -Tag "Connection"

                Register-TANSSAccessToken -Token $token

                if ($PassThru) {
                    Write-PSFMessage -Level System -Message "Outputting TANSS.Connection object" -Tag "Connection"
                    $token
                }
            } else {
                Write-PSFMessage -Level Significant -Message "Updating AccessToken for service '($($token.Server))' as '$($token.UserName)'" -Tag "Connection"

                $token
            }
        }
    }

    end {}
}
