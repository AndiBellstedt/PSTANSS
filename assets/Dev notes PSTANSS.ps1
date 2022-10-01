# Dev PSTANSS
break
[enum]::GetValues( [PSFramework.Message.MessageLevel] ) | Select-Object @{n = "x"; e = { "$($_.value__):$($_)" } }

Import-Module .\PSTANSS\PSTANSS\PSTANSS.psd1 -Force
Get-Command -Module PSTANSS

$Server = "tansstest.indasys.de"
$Server = "tanss.indasys.de"
$Credential = Get-Credential "andreas.bellstedt"
$Credential = Get-Credential "admin"
$Credential | Export-Clixml .\tanns.xml
$Credential | Export-Clixml .\tannstest.xml
$Credential = Import-Clixml .\tanns.xml
$Credential = Import-Clixml .\tannstest.xml

$token = Connect-TANSS -Server $Server -Credential $Credential -PassThru
$token = Connect-TANSS -Server $Server -Credential $Credential -LoginToken (Read-Host -Prompt "Enter OTP") -PassThru
$token = Connect-TANSS -Server $Server -Credential $Credential -DoNotRegisterConnection -PassThru
$token = Connect-TANSS -Server $Server -Credential $Credential -PassThru -DoNotRegisterConnection
$TANSSToken = $Token
$Token = $TANSSToken

$Token = Get-TANSSRegisteredAccessToken
$Token | Export-Clixml .\TANSStoken.xml
$Token = Import-Clixml .\TANSStoken.xml
Register-TANSSAccessToken -Token $Token

Update-TANSSAccessToken
Update-TANSSAccessToken -Verbose
$Token = Update-TANSSAccessToken -PassThru
$Token = Update-TANSSAccessToken -DoNotRegisterConnection



#region lookups
[TANSS.Cache]::StopValidationRunspace = $false
[TANSS.Cache]::StopValidationRunspace = $true
Get-PSFRunspace

[TANSS.Lookup]::Companies
[TANSS.Lookup]::Contracts
[TANSS.Lookup]::CostCenters
[TANSS.Lookup]::Departments
[TANSS.Lookup]::Employees
[TANSS.Lookup]::OrderBys
[TANSS.Lookup]::Phases
[TANSS.Lookup]::Tags
[TANSS.Lookup]::Tickets
[TANSS.Lookup]::TicketStates
[TANSS.Lookup]::TicketTypes
[TANSS.Lookup]::LinkTypes
[TANSS.Lookup]::VacationTypesPredefinedApi
[TANSS.Lookup]::VacationAbsenceSubTypes
#endregion lookups



#region Get-TANSSTicket
Get-TANSSTicket -Id 1
Get-TANSSTicket -CompanyId 100000
Get-TANSSTicket -MyTickets
Get-TANSSTicket -NotAssigned
Get-TANSSTicket -AllTechnician
Get-TANSSTicket -RepairTickets
Get-TANSSTicket -NotIdentified
Get-TANSSTicket -Projects
Get-TANSSTicket -LocalTicketAdmin
Get-TANSSTicket -TicketWithTechnicanRole

#endregion Get-TANSSTicket



#region Get a specific ticket
$ticketID = "122337"
$ticketID = "114009"
$ticketID = "82"
$ticketID = "16"
$ticketID = "81"

$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/$ticketID"
$response.meta.linkedEntities
$response.meta.linkedEntities.ticketStates
$response.content


$result = Get-TANSSTicket -Id $ticketID -Verbose
$result
$result | Format-List

#endregion



#region Get a ticket history
$ticketID = "114009"
$ticketID = "3"
$response = @()
$tickets = Get-TANSSTicket -AllTechnician
foreach ($ticketid in $tickets.id) {
    $response += Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/history/$ticketID" -Verbose
}
$response.meta.linkedEntities | Format-List *
$response.meta.listProperties | Format-List *
$response.meta | Format-List
$response[1].content | Format-Table
$response.content.mails | Format-Table
$response.content.comments | Format-Table
$response.content.supports | Format-Table
#endregion



#region Get a list of company tickets
$companyID = "100000"
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/company/$companyID" -Verbose
$result = Get-TANSSTicket -CompanyId $companyID -Verbose

$result | Export-Clixml C:\Administration\Tickets.xml
$result = Import-Clixml C:\Administration\Tickets.xml
$response = $result

$response
$response.meta | Format-List
$response.meta.linkedEntities.departments
$response.meta.linkedEntities.employees
$response.meta.properties.extras.

$response.content | Format-Table
#endregion



#region Get all projects
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/projects" -Verbose

$response.meta | Format-List
$response.meta.text
$response.meta.linkedEntities
$response.meta.linkedEntities.ticketStates
$response.meta.linkedEntities.ticketTypes
$response.meta.properties | Format-List
$response.meta.properties.extras.departmentOrder

$response.content | Format-Table
$response.content | Where-Object companyid -like "1552"
#endregion



#region Get tickets from all technician
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/technician" -Verbose
$response = Get-TANSSTicket -AllTechnician

$response
$response.meta | Format-List
$response.meta.properties | Format-List
$response.meta.properties.extras
$response.meta.linkedEntities
$response.meta.linkedEntities.ticketStates
$response.meta.linkedEntities.ticketTypes

$response.content | Format-Table
$response.content[0] | Format-Table
$response.content | Measure-Object
#endregion



#region Get Ticketboard
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/ticketBoard" -Verbose

$response.meta | Format-List
$response.meta.properties | Format-List
$response.meta.properties.extras
$response.meta.linkedEntities
$response.meta.linkedEntities.employees

$response.content | Format-Table
$response.content.panels
#endregion



#region Get Ticketboard from a project
$projectId = "114009"
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/ticketBoard/project/$projectId" -Verbose

$response.meta | Format-List
$response.meta.properties | Format-List
$response.meta.properties.extras
$response.meta.linkedEntities
$response.meta.linkedEntities.employees

$response.content[0] | Format-Table
$response.content.panels
#endregion



#region query companyCategories
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/companyCategories" -Verbose

$response.meta.properties.extras
$response.content
$response.content[0].types | Format-Table
#endregion


#region company
#region search company
help Find-TANSSObject -ShowWindow
$result = Find-TANSSObject -Company -Text "Test" -ResultSize 100
$result = Find-TANSSObject -Company -Text "07" -ResultSize 10000 -Verbose
$result = Find-TANSSObject -Company -Text "07" -ResultSize 10000 -ShowInactive -ShowLocked -Verbose
$result
$result.count
$result | Out-GridView
$result | Group-Object CompanyType | Sort-Object name
$result | Group-Object IsActive | Sort-Object name
$result | Group-Object IsLocked | Sort-Object name
$result | Group-Object IsPrivateCustomer | Sort-Object name


$body = @{
    areas   = @("COMPANY")
    query   = "Stuttgart"
    configs = @{
        company = @{
            maxResults = 10000
        }
    }
}
$response = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/search" -Body $body -Verbose
$response.content
$response.content.companies | Format-Table
$response.content.companies | Measure-Object

$response.meta.text
$response.meta.properties.extras
#endregion search company


$response = Invoke-TANSSRequest -Type Put -ApiPath "backend/api/v1/companies/" -Body @{
    #"searchText" = "inda"
    #"companyTypeIds" = @(1, 2, 3, 100000)
    "fetchEmployees"   = $false
    "checkPermissions" = $false
}
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/salutations"
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/companies/properties"
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/companies/100000"
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/companies/100000/employees"
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/companies/search?query=ind"
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/companies/departments?withEmployees=true"
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/companies/technicianRecommendation/100000"
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/companies/technicianRecommendation/100000"
$response
$response.meta
$response.content | Format-Table

#endregion company


#region search Employee
help Find-TANSSObject -ShowWindow
$result = Find-TANSSObject -Employee -Text "Test" -ResultSize 100 -Verbose
$result = Find-TANSSObject -Employee -Text "07" -ResultSize 10000 -GetCategories $true -GetCallbacks $true -Verbose -Token $token
$result = Find-TANSSObject -Employee -Text "07" -ResultSize 10000 -Status Active -GetCategories $true -GetCallbacks $true -Verbose -Token $token
$result = Find-TANSSObject -Employee -Text "07" -ResultSize 10000 -CompanyId 100000 -Verbose
$result
$result.count
$result | Out-GridView
$result[0].BaseObject
$result[0] | Format-Table
$result[0] | Format-List
$result.BaseObject | Out-GridView

$result | Group-Object IsActive | Sort-Object name
$result | Group-Object Role | Sort-Object name
$result | Group-Object EmployeeCategory | Sort-Object name
$result | Group-Object Department | Sort-Object count -Descending



$body = @{
    areas   = @("EMPLOYEE")
    query   = "07"
    configs = @{
        employee = @{
            maxResults = 10000
            inactive   = $true
            categories = $true
            callbacks  = $true
        }
    }
}
$response = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/search" -Body $body -Verbose
$response.meta
$response.meta.linkedEntities | Format-List
$response.meta.linkedEntities.companies
$response.meta.linkedEntities.employeeCategories
$response.content
$response.content.employees | Format-Table
$response.content.employees | Out-GridView
$response.content.employees | Measure-Object

$response.meta.text
$response.meta.properties.extras
#endregion



#region search Ticket
help Find-TANSSObject -ShowWindow
$result = Find-TANSSObject -Ticket -Text "Bellstedt" -ResultSize 200000 -Verbose
$result = Find-TANSSObject -Ticket -Text "4.7.2" -ResultSize 200000 -Verbose -Token $token
$result = Find-TANSSObject -Ticket -Text "4.7.2" -ResultSize 200000 -PreviewContentMaxChars 10 -Verbose -Token $token
$result = Find-TANSSObject -Ticket -Text "S2D" -ResultSize 200000 -CompanyId 100000 -Verbose
$result.count
$result | Get-Member
$result | Out-GridView
$result[0].BaseObject
$result[0] | Format-Table
$result[0] | Format-List
$result.BaseObject | Out-GridView

$result | Where-Object status -notlike "erledigt" | Format-List
$result | Where-Object status -notlike "erledigt" | Get-TANSSTicket -Verbose | Format-List

$result | Group-Object Status | Sort-Object name
$result | Group-Object Companz | Sort-Object name
$result | Group-Object EmployeeAssigned | Sort-Object name



$body = @{
    areas   = @("TICKET")
    query   = "4.7.2"
    configs = @{
        employee = @{
            maxResults = 1000000
            #PreviewContentMaxChars = 10
        }
    }
}
$response = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/search" -Body $body -Verbose -Token $token
$response.meta
$response.meta.linkedEntities | Format-List
$response.meta.linkedEntities.companies
$response.meta.linkedEntities.employeeCategories
$response.content
$response.content.tickets | Format-Table
$response.content.tickets | Out-GridView
$response.content.tickets | Measure-Object
Get-TANSSTicket -Id $response.content.tickets.id -Verbose

$response.meta.text
$response.meta.properties.extras
#endregion



#region Tickethandling
# Create ticket
$ticket = New-TANSSTicket -Company 'indasys IT Systemhaus AG - TESTSYSTEM' -Client 'indasys TanssTest Admin' -OrderBy "persönlich" -Title "Überraschung $(get-date -Format s)" -Description "Something wild and random"  -Type 'Störung / Incident' -DueDate (Get-Date).AddDays(2) -Attention YES -ExternalTicketId 12345 -EmployeeAssigned 'Mitarbeiter, Technik' -Department "Technik" -Deadline (Get-Date).AddDays(4) -SeparateBilling $true -EstimatedMinutes 30  -OrderNumber 112233
$ticket = New-TANSSTicket -Company 'indasys IT Systemhaus AG - TESTSYSTEM' -Client 'indasys TanssTest Admin' -OrderBy "telefonisch" -Title "Repair Überraschung $(get-date -Format s)" -Description "Something wild and random"  -Type 'Störung / Incident' -IsRepair $true -DueDate (Get-Date).AddDays(1) -Attention YES -ExternalTicketId 12345 -EmployeeAssigned 'Mitarbeiter, Technik' -Deadline (Get-Date).AddDays(7) -EstimatedMinutes 30
$ticket
Get-TANSSTicket -Id 80, 81
$ticket = Get-TANSSTicket -Id 80
Get-TANSSTicket -Id 82 | Format-Table id, title, *link*


# Change / Set ticket
$ticket | Set-TANSSTicket -NewTitle "Überraschung abc" -Verbose
$ticket | Set-TANSSTicket -OrderBy "persönlich" -Department "Technik" -Type 'Änderung / Minor change' -Status 'Abschließende Überprüfung'


# Remove ticket
$ticketID = "83"
$result = Get-TANSSTicket -Id $ticketID -Verbose
$result | Remove-TANSSTicket -Verbose


#endregion Tickethandling



#region Technican/ Employee
#region get Technican
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/employees/technicians" -Verbose
$response

$response.meta | Format-List
$response.meta.properties | Format-List
$response.meta.properties.extras

$response.content | Format-Table
$response.content[0] | Format-List


$result = Get-TANSSTechnican
Get-TANSSTechnican -Name "*a*"
Get-TANSSTechnican -Name "*a*", "*servic*" -Verbose
Get-TANSSTechnican -Id 6
#endregion get Technican

#region Create new employee

$body = @{
    "id"                 = 0
    "name"               = "1234Test User AnBe"
    "firstName"          = "1234An"
    "lastName"           = "1234Be"
    "salutationId"       = 0
    "departmentId"       = 0
    "room"               = "Room"
    "telephoneNumber"    = "+49 (711) 12 34 56 7"
    "emailAddress"       = "anbe@test.com"
    "carId"              = 0
    "mobilePhone"        = "+49 (711) 12 34 56 7"
    "initials"           = "AnBe"
    "workingHourModelId" = 0
    "accountingTypeId"   = 0
    "privatePhoneNumber" = "+49 (711) 12 34 56 7"
    "active"             = $true
    "erpNumber"          = "0"
    "personalFaxNumber"  = "+49 (711) 12 34 56 7"
    "role"               = "role"
    "titleId"            = 0
    "language"           = ""
    "telephoneNumberTwo" = "+49 (711) 12 34 56 7"
    "mobileNumberTwo"    = "+49 (711) 12 34 56 7"
    "birthday"           = "0000-00-00"
    "companyAssignments" = @(
        @{
            "companyId" = 4
        }
    )
}
$response = Invoke-TANSSRequest -Type Post -ApiPath "backend/api/v1/employees" -Body $body -Verbose
$response.meta

$response.content.companyAssignments

$t = [TANSS.Employee]@{
    BaseObject = $response.content
    Id         = $response.content.id
}
$t | Format-List

help New-TANSSEmployee
$employee = New-TANSSEmployee -Verbose -Name "Test, AnBe" -WhatIf

$invokeParam = @{
    "Name"               = "Test User AnBe"
    "firstName"          = "An"
    "lastName"           = "Be"
    "room"               = "Room"
    "telephoneNumber"    = "+49 (711) 12 34 56 7"
    "emailAddress"       = "anbe@test.com"
    "mobilePhone"        = "+49 (711) 12 34 56 7"
    "initials"           = "AnBe"
    "privatePhoneNumber" = "+49 (711) 12 34 56 7"
    "active"             = $true
    "erpNumber"          = "0"
    "personalFaxNumber"  = "+49 (711) 12 34 56 7"
    "role"               = "role"
    "language"           = ""
    "telephoneNumberTwo" = "+49 (711) 12 34 56 7"
    "mobileNumberTwo"    = "+49 (711) 12 34 56 7"
    "birthday"           = "01.01.1900"
}
$employee = New-TANSSEmployee @invokeParam -Verbose

$employee = New-TANSSEmployee -Name "Test, AnBe"
$employee = New-TANSSEmployee -Name "AnBe Test"
$employee = New-TANSSEmployee -Name "SuperTest"

$employee = New-TANSSEmployee -Verbose -Name "Bellstedt, Andreas (Test)" -FirstName "Andreas" -LastName "Bellstedt" -Email "anbe@test.com" -Initials "AnBe" -IsActive $true -CompanyName "Musterfirma", "TestA", "TestB" -Department "Technik"

$employee | Format-Table
$employee.BaseObject

#endregion


# Get employee
$employeeId = 2
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/employees/$($employeeId)"
$response.meta.linkedEntities | Format-List *
$response.content | Format-List

#endregion



#region Vacation API in beta
# Get additional Vacationtypes
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/salutations/1"
$ApiPath = "backend/api/v1/salutations"

$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/vacationRequests/planningAdditionalTypes"
$response.content | Format-Table
[TANSS.Lookup]::VacationTypes
Get-TANSSVacationAbsenceSubType


# Query Vacation records
$body = @{
    "year"        = 2022
    #"month" = 1
    "employeeIds" = @( 2, 3 )
    #"departmentIds" = @( )
    #"planningTypes" = @(
    #    "VACATION",
    #    "ILLNESS",
    #    "ABSENCE",
    #    "STAND_BY",
    #    "OVERTIME"
    #)
    #"planningAdditionalIds" = @()
    #"statesOnly" = @(
    #    "NEW",
    #    "REQUESTED",
    #    "APPROVED",
    #    "DECLINED"
    #)
}
$response = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/vacationRequests/list" -Body $body
$response
$response.meta | Format-List *
$response.meta.linkedEntities

$response.content | Format-List
$response.content.vacationRequests
$response.content.employeeSummaries.'2'.vacationDaysForYear



# Query vacation information
$vacationType = "VACATION"
$vacationType = "ILLNESS"
$vacationType = "ABSENCE"
$vacationType = "STAND_BY"
$vacationType = "OVERTIME"

$StartDate = (Get-Date -Date (Get-Date).AddDays( -4 ) -Format "dd.MM.yyyy")
$EndDate = (Get-Date -Date (Get-Date).AddDays( -2 ) -Format "dd.MM.yyyy")
$RequesterId = [TANSS.Lookup]::Employees | Out-GridView -OutputMode Single | Select-Object -ExpandProperty Name
$_startDate = [int][double]::Parse((Get-Date -Date $StartDate -UFormat %s))
$_endDate = [int][double]::Parse((Get-Date -Date $EndDate -UFormat %s))
$body = @{
    "requesterId"  = $RequesterId
    "planningType" = $vacationType
    "startDate"    = $_startDate
    "endDate"      = $_endDate
}
$response = Invoke-TANSSRequest -Type POST -ApiPath "backend/api/v1/vacationRequests/properties" -Body $body
$response.meta | Format-List *
$response.content | Format-Table
$response.content | Format-List *
$response.content.days
$tnsVactionRequest = $response.content



help Add-TANSSVacationRequest
# Vacation
Add-TANSSVacationRequest -Vacation -StartDate "01.10.2022" -EndDate "10.10.2022"
Add-TANSSVacationRequest -Illness -StartDate "01.10.2022" -EndDate "10.10.2022"
Add-TANSSVacationRequest -Standby -StartDate "01.10.2022" -EndDate "10.10.2022"
Add-TANSSVacationRequest -Overtime -StartDate "01.10.2022" -EndDate "10.10.2022"
Add-TANSSVacationRequest -Absence -StartDate "01.10.2022" -EndDate "10.10.2022"
Add-TANSSVacationRequest -Absence -AbsenceSubTypeName "Sonderurlaub"  -StartDate "01.10.2022" -EndDate "10.10.2022"
Add-TANSSVacationRequest -Absence -AbsenceSubType (Get-TANSSVacationAbsenceSubType)[0] -StartDate "01.10.2022" -EndDate "10.10.2022"

# Errors
Add-TANSSVacationRequest
Add-TANSSVacationRequest -Vacation -StartDate "10.10.2022" -EndDate "01.10.2022"
Add-TANSSVacationRequest -Absence -AbsenceSubTypeName "foo" -StartDate "01.10.2022" -EndDate "10.10.2022"


Import-Module .\PSTANSS\PSTANSS\PSTANSS.psd1 -Force
Register-TANSSAccessToken -Token $Token
$Token = Get-TANSSRegisteredAccessToken
Update-TANSSAccessToken
Get-PSFMessage -Last 1 | Select-Object -Last 1 | Format-List  *

[TANSS.Lookup]::VacationAbsenceSubTypes


# Create vacation request
$_requestDate = [int][double]::Parse((Get-Date -UFormat %s))
$response.content.requestReason = "Test $(get-date)"
$response.content.requestDate = $_requestDate
$response.content.planningAdditionalId = Get-TANSSVacationAbsenceSubType | Out-GridView -OutputMode Single | Select-Object -ExpandProperty id
$body = $response.content | ConvertTo-PSFHashtable

$vacationRequest = Invoke-TANSSRequest -Type POST -ApiPath "backend/api/v1/vacationRequests" -Body $body
$vacationRequest.content
$vacationRequest.content.days

# Change vacation request
$id = $vacationRequest.content.id
$response.content.requestReason = "Test $(get-date) new"
$body = $response.content | ConvertTo-PSFHashtable
$vacationRequest = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/vacationRequests/$($id)" -Body $body
$vacationRequest
$vacationRequest.content

# Approve vacation request
$id = $vacationRequest.content.id
$body = @{
    "status" = "APPROVED"
}
$body = @{
    "status" = "DECLINED"
}

$result = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/vacationRequests/$($id)" -Body $body
$result.content

# delete vacation request
$id = $vacationRequest.content.id
$result = Invoke-TANSSRequest -Type DELETE -ApiPath "backend/api/v1/vacationRequests/$($id)" -Body $body
$result


# List vacation days of all employees
$year = 2022
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/vacationRequests/vacationDays/year/$($year)"
$response.content | Format-Table
$response.content[0].employee | Format-List



# Set vacation days of all employees
$body = @{
    "employeeId"   = 2
    "year"         = 2022
    "numberOfDays" = 30.0
    "transferred"  = 0.0
}
$response = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/vacationRequests/vacationDays" -Body $body
$response.content



# not functional - query all vacation requests of employee
$body = @{
    "year"        = 2022
    "employeeIds" = @(
        2
    )
}
$response = Invoke-TANSSRequest -Type Get -ApiPath "backend/api/v1/vacationRequests/vacationDays" -Body $body
$response.content


#endregion


#regions API routes from JAR
$ApiPath = "backend/api/v1/companies"
$ApiPath = "backend/api/v1/companies/1"
$ApiPath = "backend/api/v1/companies/1/employees"
$ApiPath = "backend/api/v1/companies/search?query=ind"
$ApiPath = "backend/api/v1/companies/departments?withEmployees=true"

$Type = "Get"
$Type = "Put"

$response = Invoke-TANSSRequest -Type $Type -ApiPath $ApiPath -Verbose
$response
$response.meta
$response.content

#endregions API routes from JAR