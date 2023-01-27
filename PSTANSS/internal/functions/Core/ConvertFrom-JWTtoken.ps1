function ConvertFrom-JWTtoken {
    <#
    .SYNOPSIS
        Converts access tokens to readable objects

    .DESCRIPTION
        Converts access tokens to readable objects

    .PARAMETER TokenText
        The Token to convert

    .EXAMPLE
        PS C:\> ConvertFrom-JWTtoken -Token $TokenText

        Converts the content from variable $TokenText to an object
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $TokenText
    )

    # Validate as per https://tools.ietf.org/html/rfc7519 - Access and ID tokens are fine, Refresh tokens will not work
    if ((-not $TokenText.Contains(".")) -or (-not $TokenText.StartsWith("eyJ"))) {
        $msg = "Invalid data or not an access/refresh token. $($TokenText)"
        Stop-PSFFunction -Message $msg -Tag "JWT" -EnableException $true -Exception ([System.Management.Automation.RuntimeException]::new($msg))
    }

    # Split the token in its parts
    $tokenParts = $TokenText.Split(".")

    # Work on header
    $tokenHeader = [System.Text.Encoding]::UTF8.GetString( (ConvertFrom-Base64StringWithNoPadding $tokenParts[0]) )
    $tokenHeaderJSON = $tokenHeader | ConvertFrom-Json

    # Work on payload
    $tokenPayload = [System.Text.Encoding]::UTF8.GetString( (ConvertFrom-Base64StringWithNoPadding $tokenParts[1]) )
    $tokenPayloadJSON = $tokenPayload | ConvertFrom-Json

    # Work on signature
    $tokenSignature = ConvertFrom-Base64StringWithNoPadding $tokenParts[2]

    # Output
    $resultObject = [PSCustomObject]@{
        "alg"       = $tokenHeaderJSON.alg
        "typ"       = $tokenHeaderJSON.typ
        "kid"       = $tokenHeaderJSON.kid
        "sub"       = $tokenPayloadJSON.sub
        "exp"       = [datetime]::new(1970, 1, 1, 0, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($tokenPayloadJSON.exp).ToLocalTime()
        "type"      = $tokenPayloadJSON.type
        "signature" = $tokenSignature
    }

    $resultObject
}