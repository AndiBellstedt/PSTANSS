function New-TANSSServiceToken {
    <#
    .Synopsis
        Create a new (user unspecific) api service access token object

    .DESCRIPTION
        Create a new api service access token object.
        Apart from the regular user login, there are aspects and api routes, that are
        only available via explicit service token.

        This function allows you to create a service token to give to other functions,
        that require such a token.

    .PARAMETER Server
        Name of the service the token is generated from

    .PARAMETER ServiceToken
        A API token generated within Tanss to access specific TANSS modules explicit via
        API service as a non-employee-account.

        For security reaons, the parameter only accept secure strings.
        Please avoid plain-text for sensitive informations!
        To generate secure strings use:
        $ServiceTokenSecureString = Read-Host -AsSecureString

    .PARAMETER Protocol
        Specifies if the service connection is done with http or https

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> $tanssServiceToken = New-TANSSServiceToken -Server "tanss.corp.company.com" -ServiceToken $ServiceTokenSecureString

        Outputs a ServiceToken as a TANSS.Connection object for "tanss.corp.company.com" with the api key from the variable $ServiceTokenSecureString

        API variable $ServiceTokenSecureString hast to be a securestring.
        ($ServiceTokenSecureString = Read-Host -AsSecureString)

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $true,
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
        [ValidateNotNull()]
        [String]
        $Server,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias("ApiKey", "Password", "AccessToken", "Token")]
        [securestring]
        $ServiceToken,

        [ValidateSet("HTTP", "HTTPS")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Protocol = "HTTPS"
    )

    begin {
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        # Ensure Prefix
        if ($protocol -eq 'HTTP') {
            Write-PSFMessage -Level Important -Message "Unsecure $($protocol) connection  with possible security risk detected. Please consider switch to HTTPS!" -Tag "ServiceToken"
            $prefix = 'http://'
        } else {
            Write-PSFMessage -Level System -Message "Using secure $($protocol) connection." -Tag "ServiceToken"
            $prefix = 'https://'
        }

        # Validate Server Parameter to avoid accidentally input bearer token information in $Server
        try {
            $null = ConvertFrom-JWTtoken -TokenText $Server
            $serverIsTokenObject = $true
        } catch {
            $serverIsTokenObject = $false
        }
        if (($Server.StartsWith("Bearer")) -or ($Server.Length -gt 256) -or ($serverIsTokenObject)) {
            if ($Server.Length -gt 10) {
                $textlength = $Server.Length / 2
            } elseif ($Server.Length -gt 5) {
                $textlength = 4
            } else {
                $textlength = 2
            }
            Stop-PSFFunction -Message "The specified Server '$($Server.Substring(0, $textlength))****' looks like a service token. ServiceToken has to be piped in as a SecureString or has to be specified via parameter '-ServiceToken'. For security reason, please don't use plaintext for sensitive information." -EnableException $true -Cmdlet $pscmdlet -Tag "ServiceToken"
        }

        # Read JWT from service token
        $TokenText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServiceToken))
        if ($TokenText.StartsWith("Bearer")) {
            Write-PSFMessage -Level System -Message "Found Bearer token information. Going to extract JWT" -Tag "ServiceToken"
            $TokenText = $TokenText.split(" ")[-1]
        }
        Write-PSFMessage -Level Verbose -Message "Reading JWT information from serviceToken" -Tag "ServiceToken"
        $tokenInfo = ConvertFrom-JWTtoken -TokenText $TokenText

        # Create ServiceToken
        if (($tokenInfo.typ -like "JWT") -and $Server -and $prefix) {
            if ($pscmdlet.ShouldProcess("Service token for '$($UserName)'", "New")) {
                Write-PSFMessage -Level System -Message "Creating TANSS.Connection with service token" -Tag "ServiceToken"

                $serviceTokenObject = [TANSS.Connection]@{
                    Server            = "$($Prefix)$($Server)"
                    UserName          = $tokenInfo.sub
                    EmployeeId        = 0
                    EmployeeType      = "ServiceAccessToken"
                    AccessToken       = $ServiceToken
                    RefreshToken      = $null
                    Message           = "Explizit specified API token. May not work with all functions!"
                    TimeStampCreated  = (Get-Date)
                    TimeStampExpires  = $tokenInfo.exp
                    TimeStampModified = (Get-Date)
                }

                Invoke-TANSSTokenCheck -Token $serviceTokenObject -NoRefresh

                # output result
                $serviceTokenObject
            }
        } else {
            Write-PSFMessage -Level Important -Message "Unable to create TANSS ServiceToken object with specified ServiceToken '$($TokenText.Substring(0,10))*****'" -Tag "ServiceToken"
        }
    }

    end {}
}
