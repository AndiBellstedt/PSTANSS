function Remove-TANSSTimeStamp {
    <#
    .Synopsis
        Remove-TANSSTimeStamp

    .DESCRIPTION
        Remove a timestamp from TANSS

    .PARAMETER InputObject
        TANSS TimeStamp object to remove

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
        PS C:\> Get-TANSSTimeStamp | Remove-TANSSTimeStamp

        Remove timestamp for currently logged in employee for today

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'High'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("Timestamp")]
        [TANSS.TimeStamp[]]
        $InputObject,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
        $timeStamps = [System.Collections.ArrayList]@()
    }

    process {
        foreach ($timeStamp in $InputObject) {
            Write-PSFMessage -Level Verbose -Message "Collecting TimeStamp '$(Get-Date -Date ($timeStamp.Date) -Format 'yyyy-MM-dd HH:mm')' from employee '$($timeStamp.EmployeeName)' (Id $($timeStamp.Id))"
            $null = $timeStamps.Add($timeStamp)
        }
    }

    end {
        [array]$timeStampsOfEmployees = $timeStamps | Group-Object EmployeeId
        Write-PSFMessage -Level System -Message "Collected $(([array]$timeStamps).count) timestamp(s) for $(([array]$timeStampsOfEmployees).count) employee" -Tag "TimeStamp"

        foreach ($timeStampsOfEmployeeGroup in $timeStampsOfEmployees) {
            Write-PSFMessage -Level Verbose -Message "Working on timestamps for employee '$($timeStampsOfEmployeeGroup.group[0].EmployeeName)' (Id: $($timeStampsOfEmployeeGroup.Name))" -Tag "TimeStamp"
            if ($timeStampsOfEmployeeGroup.Name -ne $Token.EmployeeId) {
                Write-PSFMessage -Level Warning -Message "Unable to remove timestamps for employee '$($timeStampsOfEmployeeGroup.Name)'. TANSS API does not support removing timestamps of other employees than the logged in employee (Id: $($Token.EmployeeId), Name: $($Token.UserName))" -Tag "TimeStamp", "ApiLimitation" -PSCmdlet $pscmdlet
                continue
            }

            [array]$timeStampsOfDays = $timeStampsOfEmployeeGroup.Group | Group-Object { ($_.Date).Date }
            Write-PSFMessage -Level System -Message "Got $(([array]($timeStampsOfEmployeeGroup.Group)).count) timestamp(s) for $(([array]$timeStampsOfDays).count) day(s)" -Tag "TimeStamp"

            foreach ($timeStampsOfDayGroup in $timeStampsOfDays) {
                [array]$timeStampsToDelete = $timeStampsOfDayGroup.Group

                $employeeId = $timeStampsToDelete[0].EmployeeId
                $employeeName = $timeStampsToDelete[0].EmployeeName
                $dateString = Get-Date -Date $timeStampsToDelete[0].Date -Format "yyyy-MM-dd"
                Write-PSFMessage -Level Verbose -Message "Working on $(([array]$timeStampsToDelete).count) timestamp(s) from $($dateString) for employee '$($employeeName)'" -Tag "TimeStamp"

                Write-PSFMessage -Level System -Message "Going to query statistics of day '$($dateString)' for employee '$($employeeName)' (Id: $($employeeId))" -Tag "TimeStamp"
                $QueryParameter = @{
                    "employeeIds" = $employeeId
                    "from"        = ( [int32][double]::Parse((Get-Date -Date $timeStampsToDelete[0].Date.Date.ToUniversalTime() -UFormat %s)) )
                    "till"        = ( [int32][double]::Parse((Get-Date -Date $timeStampsToDelete[0].Date.Date.AddDays(1).ToUniversalTime() -UFormat %s)) )
                }
                $apiPath = Format-ApiPath -Path "api/v1/timestamps/statistics" -QueryParameter $QueryParameter
                $paramInvokeTANSSRequest = @{
                    "Type"    = "GET"
                    "ApiPath" = $apiPath
                    "Token"   = $Token
                    "WhatIf"  = $false
                }
                $response = Invoke-TANSSRequest @paramInvokeTANSSRequest
                Push-DataToCacheRunspace -MetaData $response.meta -Verbose:$false
                [array]$timeStampsOfDay = $response.content.timestamps
                Write-PSFMessage -Level System -Message "Found $($timeStampsOfDay.count) in '$($dateString)' for employee '$($employeeName)' (Id: $($employeeId))" -Tag "TimeStamp"

                [array]$timeStampsRemaining = $timeStampsOfDay | Where-Object id -NotIn $timeStampsToDelete.id
                Write-PSFMessage -Level System -Message "There will remain $($timeStampsRemaining.count) timestamps for employee '$($employeeName)' (Id: $($employeeId)) on '$($dateString)' after processing the current removal" -Tag "TimeStamp"
                $apiPath = Format-ApiPath -Path "api/v1/timestamps/$($employeeId)/day/$($dateString)" -QueryParameter @{ "autoPause" = $false }
                $body = $timeStampsRemaining | ConvertTo-PSFHashtable
                $paramInvokeTANSSRequest = @{
                    "Type"           = "PUT"
                    "ApiPath"        = $apiPath
                    "Token"          = $Token
                    "BodyForceArray" = $true
                    "WhatIf"         = $false
                }
                if ($body) { $paramInvokeTANSSRequest.Add("body", $body) }

                if ($pscmdlet.ShouldProcess("$($timeStampsToDelete.count) timestamps for '$($employeeName)' of date '$($dateString)' (EmployeeId: $($employeeId))", "Remove")) {
                    Write-PSFMessage -Level Verbose -Message "Removing $($timeStampsToDelete.count) timestamps for '$($employeeName)' of date '$($dateString)' (EmployeeId: $($employeeId))" -Tag "TimeStamp"
                    $response = Invoke-TANSSRequest @paramInvokeTANSSRequest
                }
            }
        }
    }
}
