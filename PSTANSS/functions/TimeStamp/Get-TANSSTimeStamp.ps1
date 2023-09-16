function Get-TANSSTimeStamp {
    <#
    .Synopsis
        Get-TANSSTimeStamp

    .DESCRIPTION
        Get docmented timestamps from TANSS

    .PARAMETER Start
        Starting date of the pariod to retreive timestamps for

        If not specified,the current day will be received.

    .PARAMETER End
        Enddate of the pariod to retreive timestamps for

        If not specified,the current day will be received.

    .PARAMETER EmployeeId
        The Id of the employee to retreive timestamps for

        As a default, the Id of employee logged in will be used.

    .PARAMETER EmployeeName
        The name of the employee to retreive timestamps for

        Tab completion available for known names

    .PARAMETER State
        The status of the timestamps to retreive

        Available via tab completion:
        "On", "Off", "StartPause", "EndPause"

        As a default, all states are retreived.

    .PARAMETER Type
        The type for the period to stamp

        Available via tab completion:
        "Work", "Inhouse", "Errand", "Vacation", "Illness", "PaidAbsence", "UnpaidAbsence", "Overtime", "Support"

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER PassThru
        Outputs the result to the console

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        PS C:\> Get-TANSSTimeStamp

        Get the timestamps of the current day

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [datetime]
        $Start,

        [datetime]
        $End,

        [Parameter(
            ParameterSetName = "ById",
            ValueFromPipeline = $true
        )]
        [int[]]
        $EmployeeId,

        [Parameter(
            ParameterSetName = "ByName",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string[]]
        $EmployeeName,

        [ValidateSet("Coming", "Leaving", "StartPause", "EndPause")]
        [string[]]
        $State,

        [ValidateSet("Work", "Inhouse", "Errand", "Vacation", "Illness", "PaidAbsence", "UnpaidAbsence", "Overtime", "Support")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Type,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "TimeStamp"


        # check parameter set
        switch ($parameterSetName) {
            "Default" { $EmployeeId = $Token.EmployeeId }

            "ByName" {
                Write-PSFMessage -Level System -Message "Convert EmployeeId from EmployeeName" -Tag "TimeStamp", "EmployeeName"
                $EmployeeId = @()

                foreach ($name in $EmployeeName) {
                    Write-PSFMessage -Level System -Message "Working on employee name '$($name)'" -Tag "TimeStamp", "EmployeeName"
                    [int]$id = $null

                    try {
                        $id = [int]$name
                        $nameIsNumber = $true
                    } catch {
                        $nameIsNumber = $false
                    }
                    if (-not $nameIsNumber) {
                        $id = ConvertFrom-NameCache -Name $name -Type "Employees"
                    }

                    if (-not $id) {
                        Write-PSFMessage -Level Warning -Message "No Id for employee '$($name)' found" -Tag "TimeStamp", "EmployeeName", "Warning"
                    } else {
                        Write-PSFMessage -Level System -Message "Found id '$($id)' for employee '$($name)'" -Tag "TimeStamp", "EmployeeName"
                        $EmployeeId += $id
                    }
                }
            }

            "ById" {
                # Nothing to do, Id is already in place
            }

            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }


        # Ensure there are employeeIds in the array, if not, api will always output timestamps for currently logged in user. This might produce redundant and faulty results
        if ($EmployeeId) {
            # Build api path parameters
            $apiParameters = @{
                "employeeIds" = $([string]::Join(",", $EmployeeId))
            }
            if ($Start) {
                $from = [int32][double]::Parse((Get-Date -Date $Start.ToUniversalTime() -UFormat %s))
                $apiParameters.Add("from", $from)
            } else {
                $from = [int32][double]::Parse((Get-Date -Date (Get-Date).Date.ToUniversalTime() -UFormat %s))
                $apiParameters.Add("from", $from)
            }
            if ($End) {
                $till = [int32][double]::Parse((Get-Date -Date $End.ToUniversalTime() -UFormat %s))
                $apiParameters.Add("till", $till)
            } else {
                $till = [int32][double]::Parse((Get-Date -Date (Get-Date).Date.AddDays(1).ToUniversalTime() -UFormat %s))
                $apiParameters.Add("till", $till)
            }

            # Compile api path
            $apiPath = Format-ApiPath -Path "api/v1/timestamps/info" -QueryParameter $apiParameters


            # Get data from service
            $response = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -WhatIf:$false
            Write-PSFMessage -Level Verbose -Message "$($response.meta.text) - $($response.content.timestamps.count) timestamp$(if($response.content.timestamps.count -ne 1){"s"}) received" -Tag "TimeStamp", "TimeStampRequestResult"


            # Output response
            foreach ($item in $response.content.timestamps) {
                Write-PSFMessage -Level System -Message "Create TANSS.TimeStamp object id '$($item.id)' ($( Get-Date -Date ( [datetime]::new(1970, 1, 1, 0, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($item.date).ToLocalTime()) -Format 'yyyy-MM-dd' ), $($item.type), $($item.state) )" -Tag "TimeStamp", "TimeStampRequestResult"

                # Create object
                $output = [TANSS.TimeStamp]@{
                    BaseObject = $item
                    Id         = $item.id
                }

                # filter output
                Write-PSFMessage -Level System -Message "Client side filtering for TANSS.TimeStamp object id '$($item.id)'" -Tag "TimeStamp", "TimeStampRequestResult"
                if ($State) {
                    $output = $output | Where-Object State -in $State
                }

                if ($Type) {
                    $output = $output | Where-Object State -in $Type
                }

                if($output) {
                    # Output the result
                    Write-PSFMessage -Level System -Message "Ouput TANSS.TimeStamp object id '$($item.id)'" -Tag "TimeStamp", "TimeStampRequestResult"
                    $output
                } else {
                    Write-PSFMessage -Level System -Message "TANSS.TimeStamp object id '$($item.id)' is not going to output, because of client side filtering" -Tag "TimeStamp", "TimeStampRequestResult"
                }
            }
        }
    }

    end {}
}
