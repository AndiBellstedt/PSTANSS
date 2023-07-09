function New-TANSSEmployee {
    <#
    .Synopsis
        New-TANSSEmployee

    .DESCRIPTION
        Create a new employee in TANSS

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        New-TANSSEmployee -Name "User, Test"

        Create a new employee (as technician) in your own company

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Userfriendly",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([TANSS.Employee])]
    param (
        # Fullname of the employee
        [Parameter(
            ParameterSetName = "ApiNative",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = "Userfriendly",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("Fullname", "Displayname")]
        [string]
        $Name,

        # first name of the employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("Givenname")]
        [string]
        $FirstName,

        # Last name of the employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("Surname")]
        [string]
        $LastName,


        # Id of the salutation for this employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Alias("IdSalutation")]
        [Int]
        $SalutationId = 0,


        # Id of the department which tis employee is assigned to
        [Parameter(ParameterSetName = "ApiNative")]
        [Alias("IdDepartment")]
        [Int]
        $DepartmentId,


        # Name of the department which tis employee is assigned to
        [Parameter(ParameterSetName = "Userfriendly")]
        [string]
        $Department,

        # location / room of the employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("Location")]
        [string]
        $Room,

        # Main telephone number
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("TelephoneNumber")]
        [string]
        $Phone,

        # e-Mail address
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("EmailAddress")]
        [string]
        $Email,

        # if this employee is assigned to a specific car, the id goes here
        [Parameter(ParameterSetName = "ApiNative")]
        [Alias("IdCar")]
        $CarId = 0,

        # mobile telephone number
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("MobilePhone")]
        [string]
        $Mobile,

        # initials for this employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [string]
        $Initials,

        # Working hour model for this employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Alias("IdWorkingHourModel")]
        [int]
        $WorkingHourModelId = 0,

        # Id of the accounting type for this employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Alias("IdAccountingType")]
        [int]
        $accountingTypeId = 0,

        # Private telephone number
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("PrivatePhoneNumber")]
        [string]
        $PrivateNumber,

        # True if the employee is active
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("Active")]
        [bool]
        $IsActive = $true,

        # Identification number in foreign ERP system
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [string]
        $ERPNumber,

        # Fax number
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("PersonalFaxNumber")]
        [string]
        $Fax,

        # Role for this employee
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [string]
        $Role,

        # if the employee uses a title, the id goes here
        [Parameter(ParameterSetName = "ApiNative")]
        [Alias("IdTitle")]
        [int]
        $TitleId = 0,

        # Language which this employee uses
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [string]
        $Language,

        # Second telephone number
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("TelephoneNumberTwo")]
        [string]
        $Phone2,

        # second mobile telephone number
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("MobileNumberTwo")]
        [string]
        $Mobile2,


        # Employee birthday date
        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("BirthdayDate", "DateBirthday", "DateOfBirth")]
        [datetime]
        $Birthday,

        # Company id of the ticket. Name is stored in the "linked entities" - "companies". Can only be set if the user has access to the company
        [Parameter(ParameterSetName = "ApiNative")]
        [Alias("CompanyAssignments", "IdCompany")]
        [int[]]
        $CompanyId,

        # Company name where the ticket should create for. Can only be set if the user has access to the company
        [Parameter(ParameterSetName = "Userfriendly")]
        [Alias("Company")]
        [String[]]
        $CompanyName,

        [Parameter(ParameterSetName = "ApiNative")]
        [Parameter(ParameterSetName = "Userfriendly")]
        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
        $apiPath = Format-ApiPath -Path "api/v1/employees"

        if ($Department) {
            $DepartmentId = ConvertFrom-NameCache -Name $Department -Type "Departments"
            if (-not $DepartmentId) {
                Write-PSFMessage -Level Warning -Message "No Id for department '$($Department)' found. Employee will be created with blank value on departmentId"
                #todo implement API call for departments
                $DepartmentId = 0
            }
        }

        if ($CompanyName) {
            $CompanyId = foreach ($companyItem in $CompanyName) {
                $_id = ConvertFrom-NameCache -Name $companyItem -Type Companies
                if (-not $_id) {
                    Write-PSFMessage -Level Warning -Message "No Id for company '$($companyItem)' found. Employee will be created without assignment to this company"
                } else {
                    $_id
                }
            }
            Remove-Variable -Name _id -Force -Confirm:$false -WhatIf:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore
        }

        if (-not $CompanyId) {
            $_name = ConvertFrom-NameCache -Id 100000 -Type "Companies"
            Write-PSFMessage -Level Important -Message "No company specified. Employee will be created within your own company $(if($_name) { "($($_name)) "})as a technician"

            $CompanyId = 100000

            Remove-Variable -Name _name -Force -Confirm:$false -WhatIf:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore
        }

    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        if ($parameterSetName -like "Userfriendly" -and (-not $Name)) {
            Write-PSFMessage -Level Error -Message "No name specified"
            continue
        }

        #region rest call prepare
        if ($Birthday) {
            $_birthday = Get-Date -Date $Birthday -Format "yyyy-MM-dd"
        } else {
            $_birthday = "0000-00-00"
        }

        [array]$_companies = foreach ($CompanyIdItem in $CompanyId) {
            @{
                "companyId" = $CompanyIdItem
            }
        }

        if (-not $LastName) {
            $nameParts = $Name.split(",").Trim()
            if ($nameParts.Count -eq 2) {
                # Assuming schema "<Lastname>, <Firstname>"
                $LastName = $nameParts[0]
            } elseif ($nameParts.Count -eq 1) {
                $nameParts = $Name.split(" ").Trim()
                if ($nameParts.Count -eq 2) {
                    # Assuming schema "<Firstname> <Lastname>"
                    $LastName = $nameParts[1]
                } else {
                    $LastName = $Name
                }
            } else {
                $LastName = $Name
            }
        }
        Remove-Variable -Name nameParts -Force -Confirm:$false -WhatIf:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore

        if (-not $FirstName) {
            $nameParts = $Name.split(",").Trim()
            if ($nameParts.Count -eq 2) {
                # Assuming schema "<Lastname>, <Firstname>"
                $FirstName = $nameParts[1]
            } elseif ($nameParts.Count -eq 1) {
                $nameParts = $Name.split(" ").Trim()
                if ($nameParts.Count -eq 2) {
                    # Assuming schema "<Firstname> <Lastname>"
                    $FirstName = $nameParts[0]
                } else {
                    $FirstName = ""
                }
            } else {
                $FirstName = ""
            }
        }
        Remove-Variable -Name nameParts -Force -Confirm:$false -WhatIf:$false -Verbose:$false -Debug:$false -ErrorAction Ignore -WarningAction Ignore

        if (-not $Initials -and $FirstName -and $LastName) {
            $_initials = "$(([string]$FirstName)[0])$(([string]$LastName)[0])"
        } else {
            $_initials = $Initials
        }

        $body = [ordered]@{
            "id"                 = 0
            "name"               = "$Name"
            "firstName"          = "$FirstName"
            "lastName"           = "$LastName"
            "salutationId"       = $SalutationId
            "departmentId"       = $DepartmentId
            "room"               = "$Room"
            "telephoneNumber"    = "$Phone"
            "emailAddress"       = "$Email"
            "carId"              = $CarId
            "mobilePhone"        = "$Mobile"
            "initials"           = "$_initials"
            "workingHourModelId" = $WorkingHourModelId
            "accountingTypeId"   = $accountingTypeId
            "privatePhoneNumber" = "$PrivateNumber"
            "active"             = $IsActive
            "erpNumber"          = "$ERPNumber"
            "personalFaxNumber"  = "$Fax"
            "role"               = "$Role"
            "titleId"            = $TitleId
            "language"           = "$Language"
            "telephoneNumberTwo" = "$Phone2"
            "mobileNumberTwo"    = "$Mobile2"
            "birthday"           = "$_birthday"
            "companyAssignments" = $_companies
        }
        #endregion rest call prepare

        if ($pscmdlet.ShouldProcess("Employee '$($Name)' on companyID '$([string]::Join(", ", $CompanyId))'", "New")) {
            Write-PSFMessage -Level Verbose -Message "Creating new employee '$($Name)' on companyID '$([string]::Join(", ", $CompanyId))'" -Tag "Employee" -Data $body

            $response = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body -Token $Token

            if ($response) {
                Write-PSFMessage -Level Verbose -Message "API Response: $($response.meta.text)"

                Push-DataToCacheRunspace -MetaData $response.meta

                [TANSS.Employee]@{
                    BaseObject = $response.content
                    Id         = $response.content.id
                }
            } else {
                Write-PSFMessage -Level Error -Message "Error creating employee, no response from API"
            }
        }
    }

    end {
    }
}