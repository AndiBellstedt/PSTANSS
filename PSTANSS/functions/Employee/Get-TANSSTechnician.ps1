function Get-TANSSTechnician {
    <#
    .Synopsis
        Get-TANSSTechnician

    .DESCRIPTION
        Gets all technicians of this system from default TANSS connection

    .PARAMETER Id
        ID of the technician to get
        (client side filtering)

    .PARAMETER Name
        Name of the technician to get
        (client side filtering)

    .PARAMETER FreelancerCompanyId
        If this parameter is given, also fetches the freelancers of this company.
        By default all users with a license are treated as "TANSS technicians".

    .PARAMETER ExcludeRestrictedLicenseUser
        Do not show account/ users / technicians with limited licenses

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSTechnician

        Gets all technicians of this system

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    [OutputType([TANSS.Employee])]
    Param(
        [String[]]
        $Name,

        [int[]]
        $Id,

        [int[]]
        $FreelancerCompanyId,

        [switch]
        $ExcludeRestrictedLicenseUser,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        $apiPath = Format-ApiPath -Path "api/v1/employees/technicians"
        Assert-CacheRunspaceRunning
        if (-not $FreelancerCompanyId) { $FreelancerCompanyId = 0 }
    }

    process {
        $response = @()

        $response += foreach ($companyId in $FreelancerCompanyId) {
            $queryParameter = @{}

            if ($MyInvocation.BoundParameters['ExcludeRestrictedLicenseUser'] -and $ExcludeRestrictedLicenseUser) {
                $queryParameter.Add("restrictedLicenses", $false)
            } else {
                $queryParameter.Add("restrictedLicenses", $true)
            }

            if ($companyId -ne 0) {
                Write-PSFMessage -Level System -Message "FreelancerCompanyId specified, compiling body to query freelancers of company '$($companyId)'" -Tag "Technician", "Freelancer"
                $queryParameter.Add("FreelancerCompanyId", $companyId)
            }

            $invokeParam = @{
                "Type"    = "GET"
                "ApiPath" = (Format-ApiPath -Path $apiPath -QueryParameter $queryParameter)
                "Token"   = $Token
                "WhatIf"  = $false
            }

            Invoke-TANSSRequest @invokeParam

            Remove-Variable -Name queryParameter, invokeParam -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore -InformationAction Ignore
        }


        if ($response) {
            Write-PSFMessage -Level Verbose -Message "Found $(($response.content).count) technicians" -Tag "Technician"

            foreach ($responseItem in $response) {

                # Output result
                foreach ($technician in $responseItem.content) {

                    # Do filtering on name
                    if ($MyInvocation.BoundParameters['Name'] -and $Name) {
                        $filterSuccess = $false
                        foreach ($filterName in $Name) {
                            if ($technician.Name -like $filterName) {
                                $filterSuccess = $true
                            }
                        }

                        # if filter does not hit, continue with next technician
                        if ($filterSuccess -eq $false) { continue }
                    }


                    # Do filtering on id
                    if ($MyInvocation.BoundParameters['Id'] -and $Id) {
                        $filterSuccess = $false
                        foreach ($filterId in $Id) {
                            if ([int]($technician.id) -eq $filterId) {
                                $filterSuccess = $true
                            }
                        }

                        # if filter does not hit, continue with next technician
                        if ($filterSuccess -eq $false) { continue }
                    }


                    # Query details
                    Write-PSFMessage -Level Verbose -Message "Getting details of '$($technician.name)' (Id $($technician.id))" -Tag "Technician"

                    $invokeParam = @{
                        "Type"    = "GET"
                        "ApiPath" = (Format-ApiPath -Path "api/v1/employees/$($technician.id)")
                        "Token"   = $Token
                        "WhatIf"  = $false
                    }

                    $employeeResponse = Invoke-TANSSRequest @invokeParam

                    if ($employeeResponse) {
                        Push-DataToCacheRunspace -MetaData $employeeResponse.meta

                        foreach ($employeeItem in $employeeResponse.content) {
                            Write-PSFMessage -Level Debug -Message "Found '$($employeeItem.Name)' with id $($employeeItem.id)"

                            # Output data
                            [TANSS.Employee]@{
                                BaseObject = $employeeItem
                                Id         = $employeeItem.id
                            }
                        }
                    } else {
                        Stop-PSFFunction -Message "Unexpected error searching '$($employeeResponse.content.name)' with ID '$($technician.id)'. TANSS is unable to find details of employee" -EnableException $true -Cmdlet $pscmdlet
                    }
                }
            }
        } else {
            Write-PSFMessage -Level Warning -Message "No technicians found." -Tag "Technician"
        }
    }

    end {
    }
}
