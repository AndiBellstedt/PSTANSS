function New-TANSSTimeStamp {
    <#
    .Synopsis
        New-TANSSTimeStamp

    .DESCRIPTION
        Add a new timestamp into the service

    .PARAMETER State
        The state to stamp. Has to be one of the value:
        "Coming", "Leaving", "StartPause", "EndPause"
        (Tabcompletaion available)

    .PARAMETER Type
        The type of record for you stamp a state.
        Available types:
        "Work", "Inhouse", "Errand", "Vacation", "Illness", "PaidAbsence", "UnpaidAbsence", "Overtime", "Support"
        Default type is: "Work"

    .PARAMETER Date
        The date of the timestamp

    .PARAMETER EmployeeId
        ID of the employee to timestamp for.
        If nothing is specified the currently logged in employee will be used

    .PARAMETER EmployeeName
        The name of the employee to timestamp for.
        Tabcompletion available for all known employees
        If nothing is specified the currently logged in employee will be used

    .PARAMETER AutoPause
        Tells the api to set autoPause to true

    .PARAMETER ServiceToken
        A timestamp api service token generated within TANSS.
        ServiceToken hast to be specified as a TANSS.Connection.

        A ServiceToken is required, if timestamps for other employees than the logged in one, are used
        to be written into the service.

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
    [OutputType([TANSS.TimeStamp])]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Coming", "Leaving", "StartPause", "EndPause")]
        [string]
        $State,

        [Parameter(Position = 1)]
        [ValidateSet("Work", "Inhouse", "Errand", "Vacation", "Illness", "PaidAbsence", "UnpaidAbsence", "Overtime", "Support")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Type = "Work",

        [Parameter(Position = 2)]
        [datetime]
        $Date,

        [bool]
        $AutoPause,

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

        [Parameter(
            ParameterSetName = "ById",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = "ByName",
            Mandatory = $true
        )]
        [TANSS.Connection]
        $ServiceToken,

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
            "Default" {
                Write-PSFMessage -Level System -Message "Using EmployeeId '$($Token.EmployeeId)' of '$($Token.UserName)' from given Token" -Tag "TimeStamp", "ParameterSetting"
                $EmployeeId = $Token.EmployeeId
            }

            "ByName" {
                Write-PSFMessage -Level System -Message "Convert EmployeeId from EmployeeName" -Tag "TimeStamp", "ParameterSetting"
                $EmployeeId = @()

                foreach ($name in $EmployeeName) {
                    Write-PSFMessage -Level System -Message "Working on employee name '$($name)'" -Tag "TimeStamp", "ParameterSetting"

                    $id = ConvertFrom-NameCache -Name $name -Type "Employees"
                    if (-not $id) {
                        Write-PSFMessage -Level Warning -Message "No Id for employee '$($name)' found" -Tag "TimeStamp", "ParameterSetting", "Warning"
                    } else {
                        Write-PSFMessage -Level System -Message "Found id '$($id)' for employee '$($name)'" -Tag "TimeStamp", "ParameterSetting"
                        $EmployeeId += $id
                    }
                }
            }

            "ById" {
                Write-PSFMessage -Level System -Message "EmployeeId '$($Token.EmployeeId)' already given to function" -Tag "TimeStamp", "ParameterSetting"
                # Nothing to do
            }

            Default {
                Stop-PSFFunction -Message "Unhandeled ParameterSetName. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }

        $apiStateText = ConvertFrom-TANSSTimeStampParameters -Text $State -TextType State
        $apiTypeText = ConvertFrom-TANSSTimeStampParameters -Text $Type -TextType Type

        # Compile api path
        $paramFormatApiPath = @{}
        if ($AutoPause) { $paramFormatApiPath.Add("autoPause", 'true') }
        if ($parameterSetName -like "Default") {
            # Use the "personal" api path
            $apiPath = Format-ApiPath -Path "/api/v1/timestamps" -QueryParameter $paramFormatApiPath
        } else {
            # Use the api path for api keys -> this one can write timestamps for other employees then the logged in one
            $apiPath = Format-ApiPath -Path "/api/timestamps/v1" -QueryParameter $paramFormatApiPath
        }

        # Work through employees
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
                $paramInvokeTANSSRequest = @{
                    "Type"    = "POST"
                    "ApiPath" = $apiPath
                    "Body"    = $body
                }
                # Choose token for "personal writing" or "delegated writing for other employees"
                if ($parameterSetName -like "Default") {
                    # Use standard user specific token to write timestamps for logged in user only
                    Write-PSFMessage -Level System -Message "Using Employee token from connection for API call" -Tag "TimeStamp", "ParameterSetting"
                    $paramInvokeTANSSRequest.Add("Token", $Token)
                } else {
                    # Use serviceToken to allow writing for other employees then the logged in one
                    Write-PSFMessage -Level System -Message "Using token from serviceToken parameter for API call" -Tag "TimeStamp", "ParameterSetting"
                    $paramInvokeTANSSRequest.Add("Token", $ServiceToken)
                }

                $response = Invoke-TANSSRequest @paramInvokeTANSSRequest
                Write-PSFMessage -Level Verbose -Message "$($response.meta.text) - Timestamp Id '$($response.content.id)' with status '$($response.content.state)'" -Tag "TimeStamp", "Stamping", "TimeStampRequestResult"

                if ($response) {
                    [TANSS.TimeStamp]@{
                        BaseObject = $response.content
                        Id         = $response.content.id
                    }
                }
            }
        }
    }

    end {}
}
