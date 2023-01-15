function Find-TANSSObject {
    <#
    .Synopsis
        Find-TANSSObject

    .DESCRIPTION
        Find a object via global search in TANSS
        The search has to be initiated on one of three areas. (Company, Employees, Tickets)

    .PARAMETER Company
        Initiate a search in the company area of TANSS

    .PARAMETER Employee
        Initiate a search within the employee/person database of TANSS

    .PARAMETER TicketPreview
        Initiate a search in the tickets of TANSS

    .PARAMETER Text
        The Text (id or name) to seach for

    .PARAMETER ShowInactive
        Search company records that are marked as inactive
        By default, only companies that are marked as "active"

        This is bound to company search only

    .PARAMETER ShowLocked
        Search company records that are marked as locked
        By default, only companies that are marked as "Unlocked"

        This is bound to company search only

    .PARAMETER CompanyId
        Return tickets or employees of the specified company id

        This is bound to ticket- and employee-search only

    .PARAMETER CompanyName
        Return tickets or employees of the specified company name

        This is bound to ticket- and employee-search only

    .PARAMETER Status
        Return "All", only "Active" or only "Inactive" employees.

    .PARAMETER GetCategories
        If true, categories will be fetches as well.
        The names are given in the "linked entities"-"employeeCategories"

        Default is $false

    .PARAMETER GetCallbacks
        If true, expected callbacks will be fetched as well

        Default is $false

    .PARAMETER PreviewContentMaxChars
        If defined, it overrides the to preview the content

        Default values within the api is 60

    .PARAMETER ResultSize
        The amount of objects the query will return
        To avoid long waitings while query a large number of items, the api
        by default only query an amount of 100 items within one call

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Find-TANSSObject -Company -Text "Customer X"

        Search for "Customer X" within all company data

    .EXAMPLE
        PS C:\> Find-TANSSObject -TicketPreview -Text "Issue Y"

        Search for "Issue Y" within all tickets

    .EXAMPLE
        PS C:\> "Mister T" | Find-TANSSObject -Employee

        Search "Mister T" in the employee records of all companies

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Company",
        PositionalBinding = $true,
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(ParameterSetName = "Company")]
        [switch]
        $Company,

        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [switch]
        $Employee,

        [Parameter(ParameterSetName = "Ticket-UserFriendly")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [Alias("Ticket")]
        [switch]
        $TicketPreview,

        [Parameter(ParameterSetName = "Company", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Employee-UserFriendly", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Employee-ApiNative", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Ticket-UserFriendly", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Ticket-ApiNative", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(2, [int]::MaxValue)]
        [string[]]
        $Text,

        [Parameter(ParameterSetName = "Company")]
        [switch]
        $ShowInactive,

        [Parameter(ParameterSetName = "Company")]
        [switch]
        $ShowLocked,

        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [int]
        $CompanyId,

        [Parameter(ParameterSetName = "Employee-UserFriendly", Mandatory = $true)]
        [Parameter(ParameterSetName = "Ticket-UserFriendly", Mandatory = $true)]
        [string]
        $CompanyName,

        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [ValidateSet("All", "Active", "Inactive")]
        [string]
        $Status = "All",

        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [bool]
        $GetCategories = $false,

        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [bool]
        $GetCallbacks = $false,

        [Parameter(ParameterSetName = "Ticket-UserFriendly")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [int]
        $PreviewContentMaxChars,

        [Parameter(ParameterSetName = "Company")]
        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [Parameter(ParameterSetName = "Ticket-UserFriendly")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [int]
        $ResultSize,

        [Parameter(ParameterSetName = "Company")]
        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [Parameter(ParameterSetName = "Ticket-UserFriendly")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }

        Assert-CacheRunspaceRunning

        $apiPath = Format-ApiPath -Path "api/v1/search"

        if ((-not $ResultSize) -or ($ResultSize -eq 0)) { $ResultSize = 100 }

        if ($Status) {
            switch ($Status) {
                "All" { $inactive = $true }
                "Active" { $inactive = $false }
                "Inactive" { $inactive = $true }
                Default {
                    Stop-PSFFunction -Message "Unhandeled Status. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
                }
            }
        }

        if($MyInvocation.BoundParameters['CompanyName'] -and $CompanyName) {
            $CompanyId = ConvertFrom-NameCache -Name CompanyName -Type "Companies"
            if(-not $CompanyId) {
                Write-PSFMessage -Level Warning -Message "No Id for company '$($Company)' found. Ticket will be created with blank value on CompanyId"
            }
        }

    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        switch ($parameterSetName) {
            "Company" {
                foreach ($textItem in $Text) {
                    $body = @{
                        areas   = @("COMPANY")
                        query   = $textItem.replace("*", "")
                        configs = @{
                            company = @{
                                maxResults = $ResultSize
                            }
                        }
                    }

                    $response = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $body -Token $Token

                    if ($response.content.companies) {
                        $countCompanyAll = ([array]($response.content.companies)).count
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - $($countCompanyAll) records returned"

                        if (-not $ShowInactive) {
                            $countCompanyFiltered = ([array]($response.content.companies | Where-Object { $_.inactive -like "False" })).Count
                            Write-PSFMessage -Level Verbose -Message "Filtering companies marked as inactive - keeping $($countCompanyFiltered) of $($countCompanyAll) records"
                        } else {
                            $countCompanyFiltered = $countCompanyAll
                        }

                        if (-not $ShowLocked) {
                            $countCompanyFiltered = $countCompanyFiltered - ([array]($response.content.companies | Where-Object { $_.lockout -like "True" })).Count
                            Write-PSFMessage -Level Verbose -Message "Filtering companies marked as locked - keeping $($countCompanyFiltered) of $($countCompanyAll) records"
                        }

                        foreach ($companyItem in $response.content.companies) {
                            # Filtering
                            if(-not $ShowInactive) { if($companyItem.inactive -like "True") { continue } }
                            if(-not $ShowLocked) { if($companyItem.lockout -like "True") { continue } }

                            # Output data
                            [TANSS.Company]@{
                                BaseObject = $companyItem
                                Id         = $companyItem.id
                            }
                        }
                    } else {
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - no records returned from global search"
                    }
                }
            }

            {$_ -like "Employee-ApiNative" -or $_ -like "Employee-UserFriendly"} {
                foreach ($textItem in $Text) {
                    $body = @{
                        areas   = @("EMPLOYEE")
                        query   = $textItem
                        configs = @{
                            employee = @{
                                maxResults = $ResultSize
                            }
                        }
                    }
                    if($CompanyId) { $body.configs.employee.Add("companyId", $CompanyId) }
                    if($Status) { $body.configs.employee.Add("inactive", $inactive) }
                    if("GetCategories" -in $PSCmdlet.MyInvocation.BoundParameters.Keys) { $body.configs.employee.Add("categories", $GetCategories) }
                    if("GetCallbacks" -in $PSCmdlet.MyInvocation.BoundParameters.Keys) { $body.configs.employee.Add("callbacks", $GetCallbacks) }

                    $response = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $body -Token $Token

                    if ($response.content.employees) {
                        $countEmployeeAll = ([array]($response.content.employees)).count
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - $($countEmployeeAll) records returned"

                        Push-DataToCacheRunspace -MetaData $response.meta

                        foreach ($employeeItem in $response.content.employees) {
                            # Output data
                            [TANSS.EmployeeSearched]@{
                                BaseObject = $employeeItem
                                Id         = $employeeItem.id
                            }
                        }
                    } else {
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - no records returned from global search"
                    }
                }
            }

            {$_ -like "Ticket-ApiNative" -or $_ -like "Ticket-UserFriendly"} {
                foreach ($textItem in $Text) {
                    $body = @{
                        areas   = @("TICKET")
                        query   = $textItem
                        configs = @{
                            employee = @{
                                maxResults = $ResultSize
                            }
                        }
                    }
                    if($CompanyId) { $body.configs.employee.Add("companyId", $CompanyId) }
                    if($PreviewContentMaxChars) { $body.configs.employee.Add("previewContentMaxChars", $PreviewContentMaxChars) }

                    $response = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $body -Token $Token

                    if ($response.content.Tickets) {
                        $countTicketsAll = ([array]($response.content.Tickets)).count
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - $($countTicketsAll) records returned"

                        Push-DataToCacheRunspace -MetaData $response.meta

                        foreach ($ticketItem in $response.content.Tickets) {
                            # Output data
                            [TANSS.TicketPreview]@{
                                BaseObject = $ticketItem
                                Id         = $ticketItem.id
                            }
                        }
                    } else {
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - no records returned from global search"
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
