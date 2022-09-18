function Get-TANSSVacationType {
    <#
    .Synopsis
        Get-TANSSVacationType

    .DESCRIPTION
        Retrieve the various vacation types

    .PARAMETER Id
        ID of the type to get
        (client side filtering)

    .PARAMETER Name
        Name of the type to get
        (client side filtering)

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .EXAMPLE
        Verb-Noun

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [string[]]
        $Name,

        [int[]]
        $Id,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
        $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/planningAdditionalTypes"

    }

    process {
        $response = Invoke-TANSSRequest -Type "GET" -ApiPath $apiPath -Token $Token

        if ($response) {
            Write-PSFMessage -Level Verbose -Message "Found $(($response.content).count) vacation types" -Tag "Vacation", "VacationType"

            foreach ($responseItem in $response) {
                # Output result
                foreach ($type in $responseItem.content) {
                    # Do filtering on name
                    if ($Name) {
                        $filterSuccess = $false
                        foreach ($filterName in $Name) {
                            if ($type.Name -like $filterName) {
                                $filterSuccess = $true
                            }
                        }
                        # if filter does not hit, continue with next technican
                        if ($filterSuccess -eq $false) { continue }
                    }

                    # Do filtering on id
                    if ($Id) {
                        $filterSuccess = $false
                        foreach ($filterId in $Id) {
                            if ([int]($type.id) -eq $filterId) {
                                $filterSuccess = $true
                            }
                        }
                        # if filter does not hit, continue with next technican
                        if ($filterSuccess -eq $false) { continue }
                    }

                    # Outputting TANSS.VacationType
                    $type
                }
            }
        } else {
            Write-PSFMessage -Level Warning -Message "No technicans found." -Tag "Technican"
        }
    }

    end {}
}
