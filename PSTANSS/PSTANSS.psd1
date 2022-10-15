@{
    # Script module or binary module file associated with this manifest
    RootModule         = 'PSTANSS.psm1'

    # Version number of this module.
    ModuleVersion      = '0.2.0'

    # ID used to uniquely identify this module
    GUID               = '1fc30b15-bde9-49ba-8763-d3b5060a99cd'

    # Author of this module
    Author             = 'Andreas Bellstedt'

    # Company or vendor of this module
    CompanyName        = ''

    # Copyright statement for this module
    Copyright          = 'Copyright (c) 2022 Andreas Bellstedt'

    # Description of the functionality provided by this module
    Description        = 'PowerShell Module for interacting with APP of 3rd party application TANSS'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion  = '5.0'

    # Modules that must be imported into the global environment prior to importing
    # this module
    RequiredModules    = @(
        @{ ModuleName = 'PSFramework'; ModuleVersion = '1.7.237' }
    )

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @('bin\PSTANSS.dll')

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess     = @('xml\PSTANSS.Types.ps1xml')

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess   = @('xml\PSTANSS.Format.ps1xml')

    # Functions to export from this module
    FunctionsToExport  = @(
        'Invoke-TANSSRequest',
        'Connect-TANSS',
        'New-TANSSTicket',
        'Get-TANSSRegisteredAccessToken',
        'Register-TANSSAccessToken',
        'Update-TANSSAccessToken',
        'Get-TANSSTicket',
        'Set-TANSSTicket',
        'Remove-TANSSTicket',
        'Find-TANSSObject',
        'Get-TANSSTechnican',
        'New-TANSSEmployee',
        'Get-TANSSVacationAbsenceSubType',
        'Get-TANSSVacationRequest',
        'New-TANSSVacationRequest',
        'Set-TANSSVacationRequestStatus',
        'Approve-TANSSVacationRequest',
        'Deny-TANSSVacationRequest',
        'Remove-TANSSVacationRequest',
        'Set-TANSSVacationRequest',
        'Request-TANSSVacationRequestObject'
    )

    # Cmdlets to export from this module
    #CmdletsToExport = ''

    # Variables to export from this module
    #VariablesToExport = ''

    # Aliases to export from this module
    #AliasesToExport = ''

    # List of all modules packaged with this module
    ModuleList         = @()

    # List of all files packaged with this module
    FileList           = @()

    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData        = @{

        #Support for PowerShellGet galleries.
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @(
                "TANSS", "API"
            )

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/AndiBellstedt/PSTANSS/blob/main/license'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/AndiBellstedt/PSTANSS'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/AndiBellstedt/PSTANSS/blob/main/PSTANSS/changelog.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}