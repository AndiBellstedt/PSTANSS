function Get-TANSSTechnican {
    <#
    .Synopsis
        Get-TANSSTechnican

    .DESCRIPTION
        Gets all technicians of this system from default TANSS connection

    .PARAMETER Id
        ID of the technican to get
        (client side filtering)

    .PARAMETER Name
        Name of the technican to get
        (client side filtering)

    .PARAMETER FreelancerCompanyId
        If this parameter is given, also fetches the freelancers of this company

    .PARAMETER Token
        The TANSS.Connection token

    .EXAMPLE
        Get-TANSSTechnican

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
    Param(
        [String[]]
        $Name,

        [int[]]
        $Id,

        [int[]]
        $FreelancerCompanyId,

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
            if ($companyId -ne 0) {
                Write-PSFMessage -Level System -Message "FreelancerCompanyId specified, compiling body to query freelancers of company '$($companyId)'" -Tag "Technican", "Freelancer"
                $body = @{
                    "FreelancerCompanyId" = $companyId
                }
            }

            $invokeParam = @{
                "Type"    = "GET"
                "ApiPath" = $apiPath
                "Token"   = $Token
            }
            if ($body) { $invokeParam.Add("Body", $body) }

            Invoke-TANSSRequest @invokeParam
        }


        if ($response) {
            Write-PSFMessage -Level Verbose -Message "Found $(($response.content).count) technicans" -Tag "Technican"

            foreach ($responseItem in $response) {
                # Output result
                foreach ($technican in $responseItem.content) {
                    # Do filtering on name
                    if ($Name) {
                        $filterSuccess = $false
                        foreach ($filterName in $Name) {
                            if($technican.Name -like $filterName) {
                                $filterSuccess = $true
                            }
                        }
                        # if filter does not hit, continue with next technican
                        if($filterSuccess -eq $false) { continue }
                    }

                    # Do filtering on id
                    if ($Id) {
                        $filterSuccess = $false
                        foreach ($filterId in $Id) {
                            if([int]($technican.id) -eq $filterId) {
                                $filterSuccess = $true
                            }
                        }
                        # if filter does not hit, continue with next technican
                        if($filterSuccess -eq $false) { continue }
                    }

                    Write-PSFMessage -Level Verbose -Message "Getting details of '$($technican.name)' (Id $($technican.id))" -Tag "Technican"
                    $employee = Find-TANSSObject -Employee -Text $technican.name -CompanyId 100000 -Status All -GetCategories $true -Token $Token | Where-Object id -eq $technican.id

                    if ($employee) {
                        # Outputting TANSS.Employee
                        $employee

                    } else {
                        Stop-PSFFunction -Message "Unexpected error searching '$($technican.name)' with ID '$($technican.id)'. TANSS is unable to find details of employee"
                        throw
                    }
                }
            }
        } else {
            Write-PSFMessage -Level Warning -Message "No technicans found." -Tag "Technican"
        }
    }

    end {
    }
}
