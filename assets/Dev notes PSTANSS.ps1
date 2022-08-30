# Dev PSTANSS
break

Import-Module .\PSTANSS\PSTANSS\PSTANSS.psd1 -Force
Get-Command -Module PSTANSS

$Server = "tansstest.indasys.de"
$Server = "tanss.indasys.de"
$Credential = Get-Credential "andreas.bellstedt"
$Credential = Get-Credential "admin"
$Credential = Import-Clixml .\tanns.xml
$Credential = Import-Clixml .\tannstest.xml

$token = Connect-TANSS -Server $Server -Credential $Credential -PassThru
$token = Connect-TANSS -Server $Server -Credential $Credential -LoginToken (Read-Host -Prompt "Enter OTP") -PassThru
$TANSSToken = $Token
$Token = $TANSSToken

Register-TANSSAccessToken -Token $Token
$Token = Get-TANSSRegisteredAccessToken
$Token | Export-Clixml .\TANSStoken.xml
$Token = Import-Clixml .\TANSStoken.xml


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
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/$ticketID"
$result = Get-TANSSTicket -Id $ticketID -Verbose

$response.meta.linkedEntities
$response.meta.linkedEntities.ticketStates
$response.content
#endregion


#region Get a ticket history
$ticketID = "114009"
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/history/$ticketID" -Verbose

$response.meta.linkedEntities
$response.content.mails | Format-Table
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


#region search company
$body = @{
    areas = @("COMPANY")
    query = "ask"
}
$response = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/search" -Body $body -Verbose


$response.meta.text
$response.meta.properties.extras

$response.content.companies | Format-Table
#endregion



#region Tickethandling
$i = 120
$x = [TANSS.Ticket]@{
    BaseObject = $result.content[$i]
    Id         = $result.content[$i].id
}
$x | Format-List
$x | Format-List *
$x | Format-List emp*
$x | Format-Table
$x | Out-GridView
$x.BaseObject.title
$x.Title

$y = foreach ($ticket in $responseItem.content) {
    [TANSS.Ticket]@{
        BaseObject = $ticket
        Id         = $ticket.id
    }
}
$y | Out-GridView

$ticket = New-TANSSTicket -Company 'indasys IT Systemhaus AG - TESTSYSTEM' -Client 'indasys TanssTest Admin' -OrderBy "persönlich" -Title "Überraschung $(get-date -Format s)" -Description "Something wild and random"  -Type 'Störung / Incident' -DueDate (Get-Date).AddDays(2) -Attention YES -ExternalTicketId 12345 -EmployeeAssigned 'Mitarbeiter, Technik' -Department "Technik" -Deadline (Get-Date).AddDays(4) -SeparateBilling $true -EstimatedMinutes 30  -OrderNumber 112233
$ticket = New-TANSSTicket -Company 'indasys IT Systemhaus AG - TESTSYSTEM' -Client 'indasys TanssTest Admin' -OrderBy "telefonisch" -Title "Repair Überraschung $(get-date -Format s)" -Description "Something wild and random"  -Type 'Störung / Incident' -IsRepair $true -DueDate (Get-Date).AddDays(1) -Attention YES -ExternalTicketId 12345 -EmployeeAssigned 'Mitarbeiter, Technik' -Deadline (Get-Date).AddDays(7) -EstimatedMinutes 30
$ticket
Get-TANSSTicket -Id 80, 81
$ticket = Get-TANSSTicket -Id 80
Get-TANSSTicket -Id 82 | ft id, title, *link*


$ticket | Set-TANSSTicket -NewTitle "Überraschung abc" -Verbose
$ticket | Set-TANSSTicket -OrderBy "persönlich" -Department "Technik" -Type 'Änderung / Minor change' -Status 'Abschließende Überprüfung'


#endregion Tickethandling


