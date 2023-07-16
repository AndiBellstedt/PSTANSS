function New-TANSSTimeStamp {
    <#
    .Synopsis
        New-TANSSTimeStamp

    .DESCRIPTION
        Add a new timestamp into the service

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
        PS C:\> New-TANSSTimeStamp

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Coming", "Leaving", "StartPause", "EndPause")]
        [string]
        $State,

        [ValidateSet("Work", "Inhouse", "Errand", "Vacation", "Illness", "PaidAbsence", "UnpaidAbsence", "Overtime", "Support")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Type = "Work",

        [datetime]
        $Date,

        [Parameter(
            ParameterSetName = "ById",
            ValueFromPipeline = $true
        )]
        [int[]]
        $EmployeeId,

        [Parameter(
            ParameterSetName = "ByName",
            ValueFromPipeline = $true
        )]
        [string[]]
        $EmployeeName,

        [bool]
        $AutoPause,

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

        switch ($parameterSetName) {
            "Default" { $EmployeeId = $Token.EmployeeId }

            "ByName" {
                Write-PSFMessage -Level System -Message "Convert EmployeeId from EmployeeName" -Tag "TimeStamp", "EmployeeName"
                $EmployeeId = @()

                foreach ($name in $EmployeeName) {
                    Write-PSFMessage -Level System -Message "Working on employee name '$($name)'" -Tag "TimeStamp", "EmployeeName"

                    $id = ConvertFrom-NameCache -Name $name -Type "Employees"
                    if (-not $id) {
                        Write-PSFMessage -Level Warning -Message "No Id for employee '$($name)' found" -Tag "TimeStamp", "EmployeeName", "Warning"
                    } else {
                        Write-PSFMessage -Level System -Message "Found id '$($id)' for employee '$($name)'" -Tag "TimeStamp", "EmployeeName"
                        $EmployeeId += $id
                    }
                }
            }

            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }

        switch ($State) {
            "Coming" { $apiStateText = "ON" }
            "Leaving" { $apiStateText = "OFF" }
            "StartPause" { $apiStateText = "PAUSE_START" }
            "EndPause" { $apiStateText = "PAUSE_END" }
            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }

        switch ($Type) {
            "Work" { $apiTypeText = "WORK" }
            "Inhouse" { $apiTypeText = "INHOUSE" }
            "Errand" { $apiTypeText = "ERRAND" }
            "Vacation" { $apiTypeText = "VACATION" }
            "Illness" { $apiTypeText = "ILLNESS" }
            "PaidAbsence" { $apiTypeText = "ABSENCE_PAID" }
            "UnpaidAbsence" { $apiTypeText = "ABSENCE_UNPAID" }
            "Overtime" { $apiTypeText = "OVERTIME" }
            "Support" { $apiTypeText = "DOCUMENTED_SUPPORT" }
            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }

        # compile api path
        $apiPath = Format-ApiPath -Path "api/v1/timestamps"
        if($AutoPause) { $apiPath = $apiPath + "?autoPause=true"}

        foreach ($id in $EmployeeId) {
            $name = ConvertFrom-NameCache -Id $id -Type "Employees"
            Write-PSFMessage -Level Verbose -Message "Working on employee '$($name)' (Id $($id))" -Tag "TimeStamp", "Stamping"

            # Compile body object
            $body = @{
                "employeeId" = $id
                "state"      = $apiStateText
                "type"       = $apiTypeText
            }
            if ($Date) { $body.date = [int32][double]::Parse((Get-Date -Date $Date.ToUniversalTime() -UFormat %s)) }

            # Check WhatIf or process request
            if ($pscmdlet.ShouldProcess("Timestamp for employee '$($name)' (ID: $($id)) with state '$($State)'", "New")) {
                Write-PSFMessage -Level Verbose -Message "New timestamp for employee '$($name)' (ID: $($id)) with state '$($State)'" -Tag "TimeStamp", "Stamping"

                # Push data into service
                $response = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body
                Write-PSFMessage -Level Verbose -Message "$($response.meta.text) - Timestamp Id '$($response.content.id)' with status '$($response.content.state)'" -Tag "TimeStamp", "Stamping", "TimeStampRequestResult"

                #Push-DataToCacheRunspace -MetaData $response.meta

                [TANSS.TimeStamp]@{
                    BaseObject = $response.content
                    Id         = $response.content.id
                }
            }
        }
    }

    end {}
}
