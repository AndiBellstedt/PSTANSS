# Dev PSTANSS
break

Import-Module .\PSTANSS.psd1 -Force
Get-Command -Module PSTANSS

$Server = "tansstest.indasys.de"
$Server = "tanss.indasys.de"
$Credential = Get-Credential "andreas.bellstedt"
$Protocol = "HTTPS"

$token = Connect-TANSS -Server $Server -Credential $Credential -PassThru
$token = Connect-TANSS -Server $Server -Credential $Credential -LoginToken (Read-Host -Prompt "Enter OTP") -PassThru
$TANSSToken = $Token
$Token = $TANSSToken

Register-TANSSAccessToken -Token $Token
$Token = Get-TANSSRegisteredAccessToken
$Token | Export-Clixml C:\Administration\TANSStoken.xml
$Token = Import-Clixml C:\Administration\TANSStoken.xml


#region Get a specific ticket
$ticketID = "122337"
$ticketID = "114009"
$response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/$ticketID"
Get-TANSSTicket -Id $ticketID -Verbose

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
$response = Invoke-TANSSRequest -Type PUT -ApiPath "backend/api/v1/search" -Verbose


$response.meta.text
$response.meta.properties.extras

$response.content.companies | Format-Table
#endregion
