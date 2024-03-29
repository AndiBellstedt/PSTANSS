﻿function Connect-TANSS {
    <#
    .Synopsis
        Connect-TANSS

    .DESCRIPTION
        Connect to TANSS Service

    .PARAMETER Server
        Name of the service to connect to

    .PARAMETER Credential
        The credentials to login

    .PARAMETER LoginToken
        If the user needs an -application specific- login token for MFA, this field must be set as well

    .PARAMETER Protocol
        Specifies if the connection is done with http or https

    .PARAMETER DoNotRegisterConnection
        Do not register the connection as default connection

    .PARAMETER NoCacheInit
        Do not query current existing tickets and various types to fill cache data for lookup types

    .PARAMETER PassThru
        Outputs the token to the console, even when the register switch is set

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Connect-TANSS -Server "tanss.company.com" -Credential (Get-Credential "username")

        Connects to "tanss.company.com" via HTTPS protocol and the specified credentials.
        Connection will be set as default connection for any further action.

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding(
        DefaultParameterSetName = 'Credential',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([TANSS.Connection])]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("ComputerName", "Hostname", "Host", "ServerName")]
        [String]
        $Server,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Credential'
        )]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = 'Credential')]
        [string]
        $LoginToken,

        [ValidateSet("HTTP", "HTTPS")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Protocol = "HTTPS",

        [Alias('NoRegistration')]
        [Switch]
        $DoNotRegisterConnection,

        [switch]
        $NoCacheInit,

        [switch]
        $PassThru
    )

    begin {
        $ApiPath = Format-ApiPath -Path "api/v1/user/login"
    }

    process {
        if ($protocol -eq 'HTTP') {
            Write-PSFMessage -Level Important -Message "Unsecure $($protocol) connection  with possible security risk detected. Please consider switch to HTTPS!" -Tag "Connection"
            $prefix = 'http://'
        } else {
            Write-PSFMessage -Level System -Message "Using secure $($protocol) connection." -Tag "Connection"
            $prefix = 'https://'
        }

        if ($Server -match '//') {
            if ($Server -match '\/\/(?<Server>(\w+|\.)+)') { $Server = $Matches["Server"] }
            Remove-Variable -Name Matches -Force -Verbose:$false -Debug:$false -Confirm:$false
        }

        if ($PsCmdlet.ParameterSetName -eq 'Credential') {
            if (($credential.UserName.Split('\')).count -gt 1) {
                $userName = $credential.UserName.Split('\')[1]
            } else {
                $userName = $credential.UserName
            }

            Write-PSFMessage -Level Verbose -Message "Authenticate user '$($userName)' to service '$($Prefix)$($server)'" -Tag "Connection", "Authentication"
            $param = @{
                "Uri"           = "$($prefix)$($server)/$($ApiPath)"
                "Headers"       = @{
                    "user"       = $userName
                    "password"   = $credential.GetNetworkCredential().Password
                    "logintoken" = "$($LoginToken)"
                }
                "Verbose"       = $false
                "Debug"         = $false
                "ErrorAction"   = "Stop"
                "ErrorVariable" = "invokeError"
            }
            try {
                $response = Invoke-RestMethod @param
            } catch {
                Stop-PSFFunction -Message "Error invoking rest call on service '$($Prefix)$($server)'. $($invokeError)" -Tag "Connection", "Authentication" -EnableException $true -Cmdlet $pscmdlet
            }

            if ($response.meta.text -like "Unsuccesful login attempt") {
                $msgText = "$($response.meta.text) to service '$($Prefix)$($server)'. Maybe wrong password"
                if (-not $LoginToken) {
                    $msgText = "$($msgText) or LoginToken (OTP) is needed"
                } else {
                    $msgText = "$($msgText) or LoginToken (OTP) wrong/expired"
                }
                Stop-PSFFunction -Message $msgText -Tag "Connection", "Authentication" -EnableException $true -Cmdlet $pscmdlet
            }

            if (-not $response.content.apiKey) {
                Stop-PSFFunction -Message "Something went wrong on authenticating user $($userName). No apiKey found in response. Unable login to service '$($Prefix)$($server)'" -Tag "Connection", "Authentication" -EnableException $true -Cmdlet $pscmdlet
            }
        }

        Write-PSFMessage -Level System -Message "Creating TANSS.Connection" -Tag "Connection"
        $token = [TANSS.Connection]@{
            Server            = "$($Prefix)$($Server)"
            UserName          = $userName
            EmployeeId        = $response.content.employeeId
            EmployeeType      = $response.content.employeeType
            AccessToken       = ($response.content.apiKey | ConvertTo-SecureString -AsPlainText -Force)
            RefreshToken      = ($response.content.refresh | ConvertTo-SecureString -AsPlainText -Force)
            Message           = $response.meta.text
            TimeStampCreated  = Get-Date
            TimeStampExpires  = [datetime]::new(1970, 1, 1, 0, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($response.content.expire).ToLocalTime()
            TimeStampModified = Get-Date
        }

        if (-not $NoCacheInit) { Invoke-CacheRefresh -Token $token }

        if (-not $DoNotRegisterConnection) {
            # Make the connection the default connection for further commands
            Register-TANSSAccessToken -Token $token -WhatIf:$false

            Write-PSFMessage -Level Significant -Message "Connected to service '($($token.Server))' as '$($token.UserName)' as default connection" -Tag "Connection"

            if ($PassThru) {
                Write-PSFMessage -Level System -Message "Outputting TANSS.Connection object" -Tag "Connection"
                $token
            }
        } else {
            Write-PSFMessage -Level Significant -Message "Connected to service '($($token.Server))' as '$($token.UserName)', outputting TANSS.Connection" -Tag "Connection"
            $token
        }
    }

    end {
    }
}
