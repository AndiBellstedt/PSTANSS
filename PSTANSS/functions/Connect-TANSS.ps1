function Connect-TANSS {
    <#
    .Synopsis
       Connect-TANSS

    .DESCRIPTION
       Connect to TANSS Service

    .PARAMETER Server
        Name of the service to connect to

    .PARAMETER PassThru
        Outputs the token to the console, even when the register switch is set

    .EXAMPLE
       Connect-TANSS -Server "tanss.company.com" -Credential (Get-Credential "username")

       Connects to "tanss.company.com" via HTTPS protocol and the specified credentials.
       Connection will be set as default connection for any further action.

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding(
        DefaultParameterSetName = 'Credential',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("ComputerName", "Hostname", "Host", "ServerName")]
        [String]
        $Server,

        # The credentials to login
        [Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # If the user needs an login token, this field must be set as well
        [Parameter(ParameterSetName = 'Credential')]
        [string]
        $LoginToken,

        # Specifies if the connection is done with http or https
        [ValidateSet("HTTP", "HTTPS")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Protocol = "HTTPS",

        # path for API
        [ValidateNotNullOrEmpty()]
        [String]
        $ApiPath = "backend/api/v1/user/login",

        # Do not register the connection as default connection
        [Alias('NoRegistration')]
        [Switch]
        $DoNotRegisterConnection,

        [switch]
        $PassThru
    )

    begin {
        $ApiPath = $ApiPath.Trim("/")

        if ($protocol -eq 'HTTP') {
            Write-PSFMessage -Level Important -Message "Unsecure $($protocol) connection  with possible security risk detected. Please consider switch to HTTPS!" -Tag "Connection"
            $prefix = 'http://'
        } else {
            Write-PSFMessage -Level System -Message "Using secure $($protocol) connection." -Tag "Connection"
            $prefix = 'https://'
        }
    }

    process {
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

            Write-PSFMessage -Level Verbose -Message "Authenticate user '$($userName)' to service '$($Prefix)$($server)'" -Tag "Connection"
            $param = @{
                "Uri"         = "$($prefix)$($server)/$($ApiPath)"
                "Headers"     = @{
                    "user"       = $userName
                    "password"   = $credential.GetNetworkCredential().Password
                    "logintoken" = "$($LoginToken)"
                }
                "Verbose"     = $false
                "Debug"       = $false
                "ErrorAction" = "Stop"
            }
            $response = Invoke-RestMethod @param

            if(-not $response.content.apiKey) {
                Stop-PSFFunction -Message "Something went wrong on authenticating user $($userName). Unable login to service '$($Prefix)$($server)'" -Tag "Authentication"
            }
        }

        Write-PSFMessage -Level System -Message "Creating TANSS.Connection" -Tag "Connection"
        $token = [PSCustomObject]@{
            PSTypeName        = "TANSS.Connection"
            Server            = "$($Prefix)$($Server)"
            UserName          = $userName
            EmployeeId        = $response.content.employeeId
            EmployeeType      = $response.content.employeeType
            Expire            = ([datetime]'1/1/1970').AddSeconds($response.content.expire)
            AccessToken       = ($response.content.apiKey | ConvertTo-SecureString -AsPlainText -Force)
            RefreshToken      = ($response.content.refresh | ConvertTo-SecureString -AsPlainText -Force)
            Message           = $response.meta.text
            TimeStampCreated  = Get-Date
            TimeStampModified = Get-Date
        }

        if (-not $DoNotRegisterConnection) {
            # Make the connection the default connection for further commands
            $script:TANSSToken = $token

            Write-PSFMessage -Level Significant -Message "Connected to service '($($token.Server))' as '$($token.UserName)' as default connection" -Tag "Connection"
        }

        if ($PassThru) {
            Write-PSFMessage -Level System -Message "Outputting TANSS.Connection object" -Tag "Connection"
            $token
        }
    }

    end {}
}
