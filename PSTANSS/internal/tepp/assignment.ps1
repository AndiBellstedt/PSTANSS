<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name PSTANSS.alcohol
#>


#region Ticket
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Company -Name "PSTANSS.CacheLookup.Companies"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Client -Name "PSTANSS.CacheLookup.Client"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Department -Name "PSTANSS.CacheLookup.Departments"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter EmployeeAssigned -Name "PSTANSS.CacheLookup.Employees"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter EmployeeTicketAdmin -Name "PSTANSS.CacheLookup.Employees"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Phase -Name "PSTANSS.CacheLookup.Phases"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Status -Name "PSTANSS.CacheLookup.TicketStates"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Type -Name "PSTANSS.CacheLookup.TicketTypes"
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter OrderBy -Name "PSTANSS.CacheLookup.OrderBys"

Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Company -Name "PSTANSS.CacheLookup.Companies"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Client -Name "PSTANSS.CacheLookup.Client"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Department -Name "PSTANSS.CacheLookup.Departments"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter EmployeeAssigned -Name "PSTANSS.CacheLookup.Employees"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter EmployeeTicketAdmin -Name "PSTANSS.CacheLookup.Employees"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Phase -Name "PSTANSS.CacheLookup.Phases"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Status -Name "PSTANSS.CacheLookup.TicketStates"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Type -Name "PSTANSS.CacheLookup.TicketTypes"
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter OrderBy -Name "PSTANSS.CacheLookup.OrderBys"
#endregion Ticket


#region Core
Register-PSFTeppArgumentCompleter -Command Find-TANSSObject -Parameter CompanyName -Name "PSTANSS.CacheLookup.Companies"
#endregion Core


#region Employee
Register-PSFTeppArgumentCompleter -Command New-TANSSEmployee -Parameter Department -Name "PSTANSS.CacheLookup.Departments"
Register-PSFTeppArgumentCompleter -Command New-TANSSEmployee -Parameter CompanyName -Name "PSTANSS.CacheLookup.Companies"
#endregion Employee


#region Vacation
Register-PSFTeppArgumentCompleter -Command Get-TANSSVacationType -Parameter Name -Name "PSTANSS.CacheLookup.VacationAbsenceSubTypes"

Register-PSFTeppArgumentCompleter -Command New-TANSSVacationRequest -Parameter AbsenceSubTypeName -Name "PSTANSS.CacheLookup.VacationAbsenceSubTypes"

Register-PSFTeppArgumentCompleter -Command Get-TANSSVacationRequest -Parameter EmployeeName -Name "PSTANSS.CacheLookup.Employees"
Register-PSFTeppArgumentCompleter -Command Get-TANSSVacationRequest -Parameter DepartmentName -Name "PSTANSS.CacheLookup.Departments"
Register-PSFTeppArgumentCompleter -Command Get-TANSSVacationRequest -Parameter Type -Name "PSTANSS.Parameter.GetVacationRequest.Type"
Register-PSFTeppArgumentCompleter -Command Get-TANSSVacationRequest -Parameter AbsenceSubTypeName -Name "PSTANSS.CacheLookup.VacationAbsenceSubTypes"

Register-PSFTeppArgumentCompleter -Command Set-TANSSVacationRequest -Parameter Type -Name "PSTANSS.Parameter.GetVacationRequest.Type"
Register-PSFTeppArgumentCompleter -Command Set-TANSSVacationRequest -Parameter AbsenceSubTypeName -Name "PSTANSS.CacheLookup.VacationAbsenceSubTypes"

Register-PSFTeppArgumentCompleter -Command Request-TANSSVacationRequestObject -Parameter Type -Name "PSTANSS.Parameter.GetVacationRequest.Type"
Register-PSFTeppArgumentCompleter -Command Request-TANSSVacationRequestObject -Parameter EmployeeName -Name "PSTANSS.CacheLookup.Employees"

Register-PSFTeppArgumentCompleter -Command Set-TANSSVacationEntitlement -Parameter EmployeeName -Name "PSTANSS.CacheLookup.Employees"
#endregion Vacation