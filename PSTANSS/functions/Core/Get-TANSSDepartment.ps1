function Get-TANSSDepartment {
    <#
    .Synopsis
        Get-TANSSDepartment

    .DESCRIPTION
        Get department from tanss

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .EXAMPLE
        Verb-Noun

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "All",
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "ById"
        )]
        [int[]]
        $Id,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "ByName"
        )]
        [string[]]
        $Name,

        [switch]
        $IncludeEmployeeId,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }

        Assert-CacheRunspaceRunning

        $apiPath = "backend/api/v1/employees/departments"
        $apiPath = Format-ApiPath -Path "api/v1/employees/departments"
        $deparments = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token | Select-Object -ExpandProperty content

        if ($IncludeEmployeeId) {
            Write-PSFMessage -Level Verbose -Message "IncludeEmployeeId switch is specified, going to ask for linked IDs" -Tag "Department", "IncludeEmployeeId"

            $apiPath = "backend/api/v1/companies/departments?withEmployees=true"
            $apiPath = Format-ApiPath -Path "api/v1/companies/departments?withEmployees=true"
            $deparmentsWithEmployeeId = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token | Select-Object -ExpandProperty content

            $deparments = foreach ($deparment in $deparments) {
                [array]$_employeeIds = $deparmentsWithEmployeeId | Where-Object id -like $deparment.id | Select-Object -ExpandProperty employeeIds

                $deparment | Add-Member -MemberType NoteProperty -Name employeeIds -Value $_employeeIds

                $deparment
            }
            Remove-Variable -Name deparmentsWithEmployeeId, _employeeIds, deparment -Force -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false -ErrorAction:Ignore -WarningAction:Ignore -InformationAction:Ignore
        }

        [array]$filteredDepartments = @()
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        switch ($parameterSetName) {
            "ById" {
                foreach ($item in $Id) {
                    $filteredDepartments += $deparments | Where-Object id -eq $item
                }
            }

            "ByName" {
                foreach ($item in $Name) {
                    $filteredDepartments += $deparments | Where-Object name -like $item
                }
            }

            "All" {
                $filteredDepartments = $deparments
            }

            Default {
                Stop-PSFFunction -Message "Unhandled ParameterSet '$($parameterSetName)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "Department", "SwitchException", "ParameterSet"
            }
        }
    }

    end {
        $filteredDepartments = $filteredDepartments | Sort-Object name, id -Unique
        Write-PSFMessage -Level Verbose -Message "Going to return $($filteredDepartments.count) departments" -Tag "Department", "Output"

        foreach ($deparment in $filteredDepartments) {
            Write-PSFMessage -Level System -Message "Working on department '$($deparment.name)' with id '$($deparment.id)'" -Tag "Department"

            # put id and name to cache lookups
            $name = "Departments"
            if ([TANSS.Lookup]::$name[$deparment.id] -notlike $deparment.name) {
                if ([TANSS.Lookup]::$name[$deparment.id]) {
                    Write-PSFMessage -Level Debug -Message "Update existing id '$($deparment.id)' in [TANSS.Lookup]::$($name) with value '$($deparment.name)'" -Tag "Cache"
                    [TANSS.Lookup]::$name[$deparment.id] = $deparment.name
                } else {
                    Write-PSFMessage -Level Debug -Message "Insert in [TANSS.Lookup]::$($name): $($deparment.id) - '$($($deparment.name))'" -Tag "Cache"
                    ([TANSS.Lookup]::$name).Add($deparment.id, $deparment.name)
                }
            }

            # output result
            [TANSS.Department]@{
                Baseobject = $deparment
                Id = $deparment.id
            }
        }
    }
}
