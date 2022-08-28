<#
# Example:
Register-PSFTeppScriptblock -Name "PSTANSS.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Companies" -ScriptBlock { [TANSS.Lookup]::Companies.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Client" -ScriptBlock { [TANSS.Lookup]::Employees.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Contracts" -ScriptBlock { [TANSS.Lookup]::Contracts.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.CostCenters" -ScriptBlock { [TANSS.Lookup]::CostCenters.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Departments" -ScriptBlock { [TANSS.Lookup]::Departments.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Employees" -ScriptBlock { [TANSS.Lookup]::Employees.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.OrderBys" -ScriptBlock { [TANSS.Lookup]::OrderBys.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Phases" -ScriptBlock { [TANSS.Lookup]::Phases.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Tags" -ScriptBlock { [TANSS.Lookup]::Tags.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.Tickets" -ScriptBlock { [TANSS.Lookup]::Tickets.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.TicketStates" -ScriptBlock { [TANSS.Lookup]::TicketStates.Values }
Register-PSFTeppScriptblock -Name "PSTANSS.CacheLookup.TicketTypes" -ScriptBlock { [TANSS.Lookup]::TicketTypes.Values }
