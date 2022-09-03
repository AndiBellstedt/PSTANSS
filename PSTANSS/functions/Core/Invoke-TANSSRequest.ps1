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

    .PARAMETER Body
        The body as a hashtable for the request

    .PARAMETER Token
        The TANSS.Connection token

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        Invoke-TANSSRequest -Server $Server

        Invoke a web request to API

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
        $Body,

        [TANSS.Connection]
        $Token
    )

    begin {
        if(-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        $ApiPath = Format-ApiPath -Path $ApiPath
    }

    process {
        if ($Body) {
            $bodyData = $Body | ConvertTo-Json
        } else {
            $bodyData = $null
        }

        $param = @{
            "Uri"           = "$($Token.Server)/$($ApiPath)"
            "Headers"       = @{
                "apiToken" = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token.AccessToken))
            }
            "Body"          = $bodyData
            "Method"        = $Type
            "ContentType"   = 'application/json; charset=UTF-8'
            "Verbose"       = $false
            "Debug"         = $false
            "ErrorAction"   = "Stop"
            "ErrorVariable" = "invokeError"
        }

        if ($pscmdlet.ShouldProcess("$($Type) web REST call against URL '$($param.Uri)'", "Invoke")) {
            Write-PSFMessage -Level Verbose -Message "Invoke $($Type) web REST call against URL '$($param.Uri)'"

            try {
                $response = Invoke-RestMethod @param
                Write-PSFMessage -Level System -Message "API Response: $($response.meta.text)"

                $response
                <#
                $output = $response.content
                foreach($name in ($response.psobject.Properties.name | where { $_ -notlike "content" })) {
                    $output | Add-Member -MemberType NoteProperty -Name $name -Value $response.$name -Force
                }
                $output
                #>
            } catch {
                $response = $invokeError.Message | ConvertFrom-Json
                Write-PSFMessage -Level Error -Message "$($response.Error.text) - $($response.Error.localizedText)" -Exception $response.Error.type -Tag "REST call $($Type)"
            }
        }
    }

    end {
    }
}