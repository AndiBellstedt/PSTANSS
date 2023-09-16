function Get-TANSSEmployee {
    <#
    .Synopsis
        Get-TANSSEmployee

    .DESCRIPTION
        Get employees out of TANSS service.

        You can pipe in IDs o employee objects to get refreshed data out of the service

        You can also pipe in company objects to receive employees of that company

    .PARAMETER EmployeeId
        The ID of the employee to get from TANSS service

    .PARAMETER Employee
        A TANSS.Employee object to query again from the service

    .PARAMETER CompanyId
        The ID of the company to get employees from

    .PARAMETER Company
        A passed in TANSS.Company object to query employees from

    .PARAMETER CompanyName
        The name of the company to query employees from

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Get-TANSSEmployee -EmployeeId 2

        Get the employee with ID 2 (usually the first employee created in TANSS)

    .EXAMPLE
        PS C:\> $employee | Get-TANSSEmployee

        Query the employee from variable $employee again

    .EXAMPLE
        PS C:\> Get-TANSSEmployee -CompanyId 100000

        Get all employees from company ID 100000 (your own company)

    .EXAMPLE
        PS C:\> $company | Get-TANSSEmployee

        Get all employees from company $company

    .EXAMPLE
        PS C:\> Get-TANSSEmployee -CompanyName "Company X"

        Get all employees from "Company X"

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Employee_ApiNative",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    [OutputType([TANSS.Employee])]
    Param(
        [Parameter(
            ParameterSetName = "Employee_ApiNative",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [Alias("Id")]
        [int[]]
        $EmployeeId,

        [Parameter(
            ParameterSetName = "Employee_UserFriendly",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [tanss.employee]
        $Employee,

        [Parameter(
            ParameterSetName = "Company_ApiNative",
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [int[]]
        $CompanyId,

        [Parameter(
            ParameterSetName = "Company_UserFriendly",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [tanss.company]
        $Company,

        [Parameter(
            ParameterSetName = "Company_UserFriendlyByName",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [string[]]
        $CompanyName,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        # If objects are piped in -> collect IDs
        switch ($parameterSetName) {
            "Employee_UserFriendly" { $EmployeeId = $Employee.Id }
            "Company_UserFriendly" { $CompanyId = $Company.Id }
            "Company_UserFriendlyByName" {
                $CompanyId = foreach ($_name in $CompanyName) {
                    Find-TANSSObject -Company -Text $_name -Token $Token -ShowLocked | Where-Object name -like $_name | Select-Object -ExpandProperty Id
                }
            }
        }

        switch ($parameterSetName) {
            { $_ -like "Employee_*" } {
                Write-PSFMessage -Level System -Message "Query personal employee record. $(([array]$EmployeeId).count) record(s)"

                foreach ($id in $EmployeeId) {
                    Write-PSFMessage -Level Verbose -Message "Working on employee id $($id)"

                    $response = Invoke-TANSSRequest -Type GET -ApiPath "api/v1/employees/$($id)" -Token $Token -WhatIf:$false

                    if ($response.meta.text -like "Object found") {

                        # Cache refresh
                        Push-DataToCacheRunspace -MetaData $response.meta

                        Write-PSFMessage -Level Verbose -Message "Output employee $($response.content.name)"
                        $output = [TANSS.Employee]@{
                            BaseObject = $response.content
                            Id         = $response.content.id
                        }

                        # ToDo: Filtering - add parameters (Isactive, FilterName, )

                        # Output result
                        $output

                    } else {
                        Write-PSFMessage -Level Error -Message "API returned no data"
                    }

                }
            }

            { $_ -like "Company_*" } {
                Write-PSFMessage -Level System -Message "Query corporate employee record. $(([array]$CompanyId).count) record(s)"

                foreach ($id in $CompanyId) {
                    Write-PSFMessage -Level Verbose -Message "Query employee(s) for company id $($id)"

                    $response = Invoke-TANSSRequest -Type GET -ApiPath "api/v1/companies/$($id)/employees" -Token $Token -WhatIf:$false

                    if ($response.meta.text -like "Object found") {

                        # Cache refresh
                        Push-DataToCacheRunspace -MetaData $response.meta

                        foreach ($responseItem in $response.content) {

                            Write-PSFMessage -Level Verbose -Message "Output corporate employee $($responseItem.name)"
                            $output = [TANSS.Employee]@{
                                BaseObject = $responseItem
                                Id         = $responseItem.id
                            }

                            # ToDo: Filtering - add parameters (Isactive, FilterName, )

                            # Output result
                            $output

                        }

                    } else {
                        Write-PSFMessage -Level Error -Message "API returned no data"
                    }
                }
            }

            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }
    }

    end {}
}
