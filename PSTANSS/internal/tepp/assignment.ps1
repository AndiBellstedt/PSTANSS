<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name PSTANSS.alcohol
#>

Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Company -Name PSTANSS.CacheLookup.Companies
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Client -Name PSTANSS.CacheLookup.Client
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Department -Name PSTANSS.CacheLookup.Departments
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter EmployeeAssigned -Name PSTANSS.CacheLookup.Employees
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter EmployeeTicketAdmin -Name PSTANSS.CacheLookup.Employees
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Phase -Name PSTANSS.CacheLookup.Phases
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Status -Name PSTANSS.CacheLookup.TicketStates
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter Type -Name PSTANSS.CacheLookup.TicketTypes
Register-PSFTeppArgumentCompleter -Command New-TANSSTicket -Parameter OrderBy -Name PSTANSS.CacheLookup.OrderBys

Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Company -Name PSTANSS.CacheLookup.Companies
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Client -Name PSTANSS.CacheLookup.Client
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Department -Name PSTANSS.CacheLookup.Departments
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter EmployeeAssigned -Name PSTANSS.CacheLookup.Employees
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter EmployeeTicketAdmin -Name PSTANSS.CacheLookup.Employees
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Phase -Name PSTANSS.CacheLookup.Phases
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Status -Name PSTANSS.CacheLookup.TicketStates
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter Type -Name PSTANSS.CacheLookup.TicketTypes
Register-PSFTeppArgumentCompleter -Command Set-TANSSTicket -Parameter OrderBy -Name PSTANSS.CacheLookup.OrderBys

Register-PSFTeppArgumentCompleter -Command Find-TANSSObject -Parameter CompanyName -Name PSTANSS.CacheLookup.Companies