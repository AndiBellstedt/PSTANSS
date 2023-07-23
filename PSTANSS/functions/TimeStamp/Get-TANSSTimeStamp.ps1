function Get-TANSSTimeStamp {
    <#
    .Synopsis
        Get-TANSSTimeStamp

    .DESCRIPTION
        Get docmented timestamps from TANSS

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

        [ValidateSet("On", "Off", "StartPause", "EndPause")]
        [string]
        $State,

        [ValidateSet("Work", "Inhouse", "Errand", "Vacation", "Illness", "PaidAbsence", "UnpaidAbsence", "Overtime", "Support")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Type = "Work",

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
            $response = Invoke-TANSSRequest -Type GET -ApiPath $apiPath
            Write-PSFMessage -Level Verbose -Message "$($response.meta.text) - $($response.content.timestamps.count) timestamp$(if($response.content.timestamps.count -ne 1){"s"}) received" -Tag "TimeStamp", "TimeStampRequestResult"


            # Output response
            foreach ($item in $response.content.timestamps) {
                [TANSS.TimeStamp]@{
                    BaseObject = $item
                    Id         = $item.id
                }
            }
        }
    }

    end {}
}
