function Get-TANSSVacationAbsenceType {
    <#
    .Synopsis
        Get-TANSSVacationAbsenceType

    .DESCRIPTION
        Retrieve the additional absence types for the vacation type "absence".
        If a absence on a employee is created, one of this types can be specified as more specific information.

    .PARAMETER Id
        ID of the type to get
        (client side filtering)

    .PARAMETER Name
        Name of the type to get
        (client side filtering)

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .EXAMPLE
        Get-TANSSVacationAbsenceType

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

        [array]$output = @()
    }

    process {
        $response = Invoke-TANSSRequest -Type "GET" -ApiPath $apiPath -Token $Token

        if ($response) {
            Write-PSFMessage -Level Verbose -Message "Found $(($response.content).count) vacation types" -Tag "Vacation", "VacationType"

            foreach ($type in $response.content) {
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

                # Compiling additional TANSS.Vacation.AbsenceType
                $output += [TANSS.Vacation.AbsenceType]@{
                    BaseObject = $type
                    Id         = $type.id
                }

                # Check VacationType lookup cache
                if ([TANSS.Lookup]::VacationAbsenceTypes[$type.id] -notlike $type.name) {
                    if ([TANSS.Lookup]::VacationAbsenceTypes[$type.id]) {
                        Write-PSFMessage -Level Debug -Message "Update existing id '$($id)' in [TANSS.Lookup]::VacationAbsenceTypes with value '$($type.name)'" -Tag "Cache"
                        [TANSS.Lookup]::VacationAbsenceTypes[$type.id] = $type.name
                    } else {
                        Write-PSFMessage -Level Debug -Message "Insert in [TANSS.Lookup]::VacationAbsenceTypes: $($type.id) - '$($($type.name))'" -Tag "Cache"
                        ([TANSS.Lookup]::VacationAbsenceTypes).Add($type.id, $type.name)
                    }
                }
            }
        } else {
            Write-PSFMessage -Level Warning -Message "No technicans found." -Tag "Technican"
        }
    }

    end {
        # Outputting TANSS.VacationType
        $output
    }
}
