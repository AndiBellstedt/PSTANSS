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
        [switch]
        $Ticket,

        # Text to search for
        [Parameter(ParameterSetName = "Company", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Employee-UserFriendly", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Employee-ApiNative", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Ticket-UserFriendly", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "Ticket-ApiNative", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(2, [int]::MaxValue)]
        [string[]]
        $Text,

        # The Id of the company where to search for data in.
        # Applies only if you search for employees or tickets
        [Parameter(ParameterSetName = "Employee-ApiNative")]
        [Parameter(ParameterSetName = "Ticket-ApiNative")]
        [int]
        $CompanyId,

        # The Id of the company where to search for data in.
        # Applies only if you search for employees or tickets
        [Parameter(ParameterSetName = "Employee-UserFriendly")]
        [Parameter(ParameterSetName = "Ticket-UserFriendly")]
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
                    Stop-PSFFunction -Message "Unhandeled Status. Developers mistake." -EnableException $true
                    throw
                }
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

                    $response = Invoke-TANSSRequest -Type PUT -ApiPath $apiPath -Body $body

                    if($response.content.companies) {
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - $($response.content.companies.count) records returned"

                        $company = $response.content.companies[0]
                        foreach ($company in $response.content.companies) {
                            [TANSS.Company]@{
                                BaseObject = $company
                                Id = $company.id
                            }
                        }
                    } else {
                        Write-PSFMessage -Level Verbose -Message "API response: $($response.meta.text) - no records returned from global search"
                    }
                }
            }

            "Employee" {

            }

            "Ticket" {

            }

            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true
                throw
            }
        }
    }

    end {}
}
