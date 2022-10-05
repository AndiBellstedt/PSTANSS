# VacationRequestTypes
Register-PSFTeppScriptblock -Name "PSTANSS.Parameter.GetVacationRequest.Type" -ScriptBlock { @([TANSS.Lookup]::VacationTypesPredefinedApi.Values, [TANSS.Lookup]::VacationTypesPredefinedApi.Keys) }
