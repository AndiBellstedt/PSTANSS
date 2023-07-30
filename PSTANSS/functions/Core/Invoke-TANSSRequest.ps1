function Invoke-TANSSRequest {
    <#
    .Synopsis
        Invoke-TANSSRequest

    .DESCRIPTION
        Invoke a API request to TANSS Server

    .PARAMETER Type
        Type of web request

    .PARAMETER ApiPath
        Uri path for the REST call in the API

    .PARAMETER QueryParameter
        A hashtable for all the parameters to the api route

    .PARAMETER AdditionalHeader
        Hashtable with additional values to put in the header of the request

    .PARAMETER Body
        The body as a hashtable for the request

    .PARAMETER Pdf
        if a PDF should be queried, this switch must be specified

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Invoke-TANSSRequest -Type GET -ApiPath "api/v1/something"

        Invoke a GET request to API with path api/v1/something by using the default registered token within the module

    .EXAMPLE
        PS C:\> Invoke-TANSSRequest -Type GET -ApiPath "api/v1/something" -Token $Token

        Invoke a GET request to API with path api/v1/something by using the explicit token from the variale $Token

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]
        $Type,

        [Parameter(Mandatory = $true)]
        [string]
        $ApiPath,

        [hashtable]
        $QueryParameter,

        [hashtable]
        $Body,

        [hashtable]
        $AdditionalHeader,

        [switch]
        $Pdf,

        [TANSS.Connection]
        $Token
    )

    begin {
    }

    process {
    }

    end {
        if(-not $Token) {$Token = Get-TANSSRegisteredAccessToken }
        Invoke-TANSSTokenCheck -Token $Token

        $ApiPath = Format-ApiPath -Path $ApiPath -QueryParameter $QueryParameter

        # Body
        if ($Body) {
            $bodyData = $Body | ConvertTo-Json -Compress
        } else {
            $bodyData = $null
        }


        # Header
        $header = @{
            "apiToken" = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token.AccessToken))
        }

        if($Pdf) { $header.Add("Accept","pdf") }

        if ($MyInvocation.BoundParameters['AdditionalHeader'] -and $AdditionalHeader) {
            foreach ($key in $AdditionalHeader.Keys) {
                $header.Add($key, $AdditionalHeader[$key])
            }
        }


        # Invoke request
        $param = @{
            "Uri"           = "$($Token.Server)/$($ApiPath)"
            "Headers"       = $header
            "Body"          = $bodyData
            "Method"        = $Type
            "ContentType"   = 'application/json; charset=UTF-8'
            "Verbose"       = $false
            "Debug"         = $false
            "ErrorAction"   = "Stop"
            "ErrorVariable" = "invokeError"
        }

        if ($pscmdlet.ShouldProcess("$($Type) web REST call against URL '$($param.Uri)'", "Invoke")) {
            Write-PSFMessage -Level Verbose -Message "Invoke $($Type) web REST call against URL '$($param.Uri)'" -Tag "TANSSApiRequest" -Data @{ "body" = $bodyData; "Method" = $Type}

            try {
                $response = Invoke-RestMethod @param
                Write-PSFMessage -Level System -Message "API Response: $($response.meta.text)" -Tag "TANSSApiRequest", "SuccessfulRequest" -Data @{ "response" = $response }
            } catch {
                if($invokeError[0].Message.StartsWith("{")) {
                    $response = $invokeError[0].Message | ConvertFrom-Json -ErrorAction SilentlyContinue
                }

                if($response) {
                    Write-PSFMessage -Level Error -Message "$($response.Error.text) - $($response.Error.localizedText)" -Exception $response.Error.type -Tag "TANSSApiRequest", "FailedRequest", "REST call $($Type)" -Data $invokeError[0].Message -PSCmdlet $pscmdlet -ErrorRecord $invokeError[0].ErrorRecord
                } else {
                    Write-PSFMessage -Level Error -Message "$($invokeError[0].Source) ($($invokeError[0].HResult)): $($invokeError[0].Message)" -Exception $invokeError[0].InnerException -Tag "TANSSApiRequest", "FailedRequest", "REST call $($Type)" -ErrorRecord $invokeError[0].ErrorRecord  -PSCmdlet $pscmdlet -Data $invokeError[0].Message
                }

                return
            }

            # Output
            $response
        }
    }
}