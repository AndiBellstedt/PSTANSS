function Get-TANSSEmployee {
    <#
    .Synopsis
        Verb-Noun

    .DESCRIPTION
        Description

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .PARAMETER PassThru
        Outputs the result to the console

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Get-TANSSEmployee

        Description

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
            ValueFromPipeline = $true,
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
        }

        switch ($parameterSetName) {
            { $_ -like "Employee_*" } {
                Write-PSFMessage -Level System -Message "Query personal employee record. $(([array]$EmployeeId).count) record(s)"

                foreach($id in $EmployeeId) {
                    Write-PSFMessage -Level Verbose -Message "Working on employee id $($id)"

                    $response = Invoke-TANSSRequest -Type GET -ApiPath "api/v1/employees/$($id)" -Token $Token

                    if($response.meta.text -like "Object found") {

                        # Cache refresh
                        Push-DataToCacheRunspace -MetaData $response.meta

                        Write-PSFMessage -Level Verbose -Message "Output employee $($response.content.name)"
                        $output = [TANSS.Employee]@{
                            BaseObject = $response.content
                            Id = $response.content.id
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

                foreach($id in $CompanyId) {
                    Write-PSFMessage -Level Verbose -Message "Query employee(s) for company id $($id)"

                    $response = Invoke-TANSSRequest -Type GET -ApiPath "api/v1/companies/$($id)/employees" -Token $Token

                    if($response.meta.text -like "Object found") {

                        # Cache refresh
                        Push-DataToCacheRunspace -MetaData $response.meta

                        foreach($responseItem in $response.content) {

                            Write-PSFMessage -Level Verbose -Message "Output corporate employee $($responseItem.name)"
                            $output = [TANSS.Employee]@{
                                BaseObject = $responseItem
                                Id = $responseItem.id
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
