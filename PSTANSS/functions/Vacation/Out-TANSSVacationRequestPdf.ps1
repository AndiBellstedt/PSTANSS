function Out-TANSSVacationRequestPdf {
    <#
    .Synopsis
        Out-TANSSVacationRequestPdf

    .DESCRIPTION
        Write a PDF for a vacation request from Tanss.
        This is only available for VacataRequest of Type "vacation"

    .PARAMETER InputObject
        TANSS.Vacation.Request object to output pdf file for

    .PARAMETER Id
        The Id of the vacation request

    .PARAMETER Path
        The path to output the pdf to

    .PARAMETER PassThru
        Switch parameter. If specified, the file object will be thrown out to the console

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
        PS C:\> Out-TANSSVacationRequestPdf

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ByID",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ByInputObject",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [TANSS.Vacation.Request[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ById",
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias("RequestId", "VacationRequestId")]
        [int[]]
        $Id,

        [string]
        $Path,

        [switch]
        $PassThru,

        [TANSS.Connection]
        $Token
    )

    begin {
        # Validation - Basic checks
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning


        # Check path
        if ($Path) {
            if ($Path.Contains("\")) {
                # Check if pdf filename is specified
                if ($Path.split("\")[-1] -like "*.pdf") {
                    # assume explicit specified PDF
                    $fileName = $Path.split("\")[-1]
                    $resolved = Resolve-Path -Path $Path.TrimEnd( $fileName ) -ErrorAction Ignore
                } else {
                    # assume path
                    $resolved = Resolve-Path -Path $Path  -ErrorAction Ignore
                }

                if ($resolved) {
                    $_path = $resolved | Select-Object -ExpandProperty Path
                    if ($fileName) { $_path = "$($_path)\$($fileName)" }
                } else {
                    Stop-PSFFunction -Message "Path '$($Path)' is not valid" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "OutPdf", "PathException"
                }
            } else {
                if ($Path -notlike "*.pdf") {
                    Write-PSFMessage -Level Warning -Message "Unusual behaviour, filename for outputfile does not contain '.pdf'" -Tag "VacationRequest", "OutPdf", "FileName"
                }
                $fileName = $Path

                $_path = "$(Resolve-Path -Path ".\" -ErrorAction Ignore | Select-Object -ExpandProperty Path)\$fileName"
                if (-not $_path) {
                    Stop-PSFFunction -Message "Path '$($Path)' is not valid" -EnableException $true -Cmdlet $pscmdlet -Tag "VacationRequest", "OutPdf", "PathException"
                }
            }
        } else {
            $_path = "$(Resolve-Path -Path ".\" | Select-Object -ExpandProperty Path)\"
        }
        Write-PSFMessage -Level System -Message "Specified path: $($_path)" -Tag "VacationRequest", "OutPdf"
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)" -Tag "VacationRequest", "OutPdf"

        # If Id is piped in, query vacationRequests from TANSS
        if ($parameterSetName -like "ById*") {
            $InputObject = foreach ($requestId in $Id) {
                Get-TANSSVacationRequest -Id $requestId -Token $Token
            }
        }

        foreach ($vacationRequest in $InputObject) {
            Write-PSFMessage -Level Verbose -Message "Working on '$($vacationRequest.TypeName)' VacationRequest '$($vacationRequest.Id)' ($($vacationRequest.EmployeeName)) for range '$($vacationRequest.StartDate) - $($vacationRequest.EndDate)'" -Tag "VacationRequest", "OutPdf"

            if ($vacationRequest.Type -ne "Vacation") {
                Write-PSFMessage -Level Warning -Message "VacationRequest '$(($vacationRequest.Id))' is not of type 'Vacation'. PDF output only supported for VacationRequest of type 'vacation'" -Tag "VacationRequest", "OutPdf", "Warning"
                continue
            }

            if (-not $fileName) {
                $name = "urlaubsantrag_ID$($vacationRequest.Id)_$(Get-Date -Date $vacationRequest.StartDate -Format "yyyy-MM-dd")_$(Get-Date -Date $vacationRequest.EndDate -Format "yyyy-MM-dd").pdf"
                Write-PSFMessage -Level Verbose -Message "No name specified output file. Using filename: $($name)" -Tag "VacationRequest", "OutPdf", "FileName"
                $_path = Join-Path -Path $_path -ChildPath $name
                Write-PSFMessage -Level System -Message "Output path is: $($_path)" -Tag "VacationRequest", "OutPdf", "Path"
            }

            $apiPath = Format-ApiPath -Path "api/v1/vacationRequests/$($vacationRequest.Id)/pdf"
            $downloadLink = Invoke-TANSSRequest -Type Get -ApiPath $apiPath -Pdf -WhatIf:$false

            if ($pscmdlet.ShouldProcess("PDF for vacation request '$vacationRequest.Id' from '$($vacationRequest.EmployeeName)' to '$_path'", "Out")) {
                Write-PSFMessage -Level Verbose -Message "Ouput PDF for vacation request '$vacationRequest.Id' from '$($vacationRequest.EmployeeName)' to '$_path'" -Tag "VacationRequest", "OutPdf"
                $apiPath = Format-ApiPath -Path $downloadLink.content.url
                $param = @{
                    "Uri"           = "$($Token.Server)/$($apiPath)"
                    "Headers"       = @{
                        "apiToken" = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token.AccessToken))
                    }
                    "Method"        = "GET"
                    "ContentType"   = 'application/json; charset=UTF-8'
                    "Verbose"       = $false
                    "Debug"         = $false
                    "ErrorAction"   = "Stop"
                    "ErrorVariable" = "invokeError"
                    "OutFile"       = $_path
                }
                try {
                    Invoke-RestMethod @param
                } catch {
                    Write-PSFMessage -Level Error -Message "Error on rest call: $($invokeError.ErrorRecord.Exception.Message)" -Tag "VacationRequest", "OutPdf", "RestException" -ErrorRecord $invokeError.ErrorRecord -PSCmdlet $pscmdlet
                    continue
                }

                if ($PassThru) {
                    Get-Item -Path $_path
                }
            }
        }
    }

    end {
    }
}
