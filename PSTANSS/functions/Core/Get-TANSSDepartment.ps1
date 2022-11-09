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

        $apiPath = Format-ApiPath -Path "api/v1/employees/departments"
        $departments = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token | Select-Object -ExpandProperty content

        if ($IncludeEmployeeId) {
            Write-PSFMessage -Level Verbose -Message "IncludeEmployeeId switch is specified, going to ask for linked IDs" -Tag "Department", "IncludeEmployeeId"

            $apiPath = Format-ApiPath -Path "api/v1/companies/departments?withEmployees=true"
            $deparmentsWithEmployeeId = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token | Select-Object -ExpandProperty content

            $departments = foreach ($department in $departments) {
                [array]$_employeeIds = $deparmentsWithEmployeeId | Where-Object id -like $department.id | Select-Object -ExpandProperty employeeIds

                $department | Add-Member -MemberType NoteProperty -Name employeeIds -Value $_employeeIds

                $department
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
                    $filteredDepartments += $departments | Where-Object id -eq $item
                }
            }

            "ByName" {
                foreach ($item in $Name) {
                    $filteredDepartments += $departments | Where-Object name -like $item
                }
            }

            "All" {
                $filteredDepartments = $departments
            }

            Default {
                Stop-PSFFunction -Message "Unhandled ParameterSet '$($parameterSetName)', developers mistake" -EnableException $true -Cmdlet $pscmdlet -Tag "Department", "SwitchException", "ParameterSet"
            }
        }
    }

    end {
        $filteredDepartments = $filteredDepartments | Sort-Object name, id -Unique
        Write-PSFMessage -Level Verbose -Message "Going to return $($filteredDepartments.count) departments" -Tag "Department", "Output"

        foreach ($department in $filteredDepartments) {
            Write-PSFMessage -Level System -Message "Working on department '$($department.name)' with id '$($department.id)'" -Tag "Department"

            # put id and name to cache lookups
            Update-CacheLookup -LookupName "Departments" -Id $department.Id -Name $department.Name

            # output result
            [TANSS.Department]@{
                Baseobject = $department
                Id = $department.id
            }
        }
    }
}
