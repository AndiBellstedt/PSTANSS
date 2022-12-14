function Find-TANSSObject {
    <#
    .Synopsis
        Find-TANSSObject

    .DESCRIPTION
        Find a object via global search in TANSS

    .PARAMETER ResultSize
        The amount of objects the query will return
        To avoid long waitings while query a large number of items, the api
        by default only query an amount of 100 items within one call

    .EXAMPLE
        Find-TANSSObject -Company -Text "Customer X"

        Search for "Customer X" within all company data

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
        # Specify to search for company data
        [Parameter(ParameterSetName = "Company")]
        [switch]
        $Company,

        # Specify to search for company data
        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [switch]
        $Employee,

        # Specify to search for company data
        [Parameter(ParameterSetName = "Ticket-UserFriendly")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [Alias("Ticket")]
        [switch]
        $TicketPreview,

        # Text to search for
        [Parameter(ParameterSetName = "Company", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Employee-UserFriendly", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Employee-ApiNative", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Ticket-UserFriendly", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Ticket-ApiNative", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(2, [int]::MaxValue)]
        [string[]]
        $Text,

        # By default, only companies that are marked as "active"
        # If this switch is specified, inactive companies are also outputted
        [Parameter(ParameterSetName = "Company")]
        [switch]
        $ShowInactive,

        # By default, only companies that are marked as "Unlocked"
        # If this switch is specified, locked companies are also outputted
        [Parameter(ParameterSetName = "Company")]
        [switch]
        $ShowLocked,

        # The Id of the company where to search for data in.
        # Applies only if you search for employees or tickets
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [int]
        $CompanyId,

        # The Id of the company where to search for data in.
        # Applies only if you search for employees or tickets
        [Parameter(ParameterSetName = "Employee-UserFriendly", Mandatory = $true)]
        [Parameter(ParameterSetName = "Ticket-UserFriendly", Mandatory = $true)]
        [string]
        $CompanyName,

        # Specify if inactive users are filtered out
        # By default "all" employees are gathered
        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [ValidateSet("All", "Active", "Inactive")]
        [string]
        $Status = "All",

        # if true, categories will be fetches as well. The names are given in the
        # "linked entities" - "employeeCategories" (default = false)
        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [bool]
        $GetCategories = $false,

        # if true, expected callbacks will be fetched as well (default = false)
        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [bool]
        $GetCallbacks = $false,

        # if defined, overrides the to preview the content (default values is 60)
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

        if($Company) {
            $CompanyId = ConvertFrom-NameCache -Name $Company -Type "Companies"
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
                        query   = $textItem
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
                            [TANSS.Employee]@{
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
