<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.

# Example Configuration
Set-PSFConfig -Module 'PSTANSS' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>



#region Module configurations
Set-PSFConfig -Module 'PSTANSS' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'PSTANSS' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -Module 'PSTANSS' -Name 'API.RestPathPrefix' -Value "backend/" -Initialize -Validation 'string' -Description "Individual URI path for API webservices on TANSS server. HuckIT specifies the rest calls on 'https://api-doc.tanss.de/', but on prod-installations for TANSS, there maybe a prefix in the path of the api rest calls."

#endregion Module configurations



#region Module variables
New-Variable -Name TANSSToken -Scope Script -Visibility Public -Description "Variable for registered token. This is for convinience use with the commands in the module" -Force

#endregion Module variables



#region Manual Lookup definitions
[TANSS.Lookup]::LinkTypes = @{
    "0"  = "Keine Zuweisung"
    "1"  = "PC"
    "2"  = "Kunde (generell)"
    "3"  = "Mitarbeiter"
    "4"  = "Peripherie"
    "5"  = "Komponente"
    "6"  = "Lizenz"
    "24" = "Domain"
}

[TANSS.Lookup]::VacationTypesPredefinedApi = [ordered]@{
    "VACATION" = "Urlaub"
    "ILLNESS"  = "Krankheit"
    "ABSENCE"  = "Abwesenheit"
    "STAND_BY" = "Bereitschaft"
    "OVERTIME" = "Überstunden abfeiern"
}

[TANSS.Lookup]::VacationAbsenceTypes = @{}


#endregion Manual Lookup definitions
