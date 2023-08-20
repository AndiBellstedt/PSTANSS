function ConvertFrom-TANSSTimeStampParameter {
    <#
    .Synopsis
        ConvertFrom-TANSSTimeStampParameter

    .DESCRIPTION
        Convert display names for Type & State parameter into api texts

    .PARAMETER Text
        If not specified, the registered default token from within the module is going to be used

    .PARAMETER TextType
        Specifies if the text is a timestampe "state" or "type"

    .EXAMPLE
        PS C:\> ConvertFrom-TANSSTimeStampParameter -Text "Coming" -TextType "State"

        Outputs "On" as a "comming state for TANSS api

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true
            )]
        [ValidateSet("Coming", "Leaving", "StartPause", "EndPause", "Work", "Inhouse", "Errand", "Vacation", "Illness", "PaidAbsence", "UnpaidAbsence", "Overtime", "Support")]
        [string]
        $Text,

        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("State", "Type")]
        [String]
        $TextType
    )

    begin {}

    process {
        Write-PSFMessage -Level Debug -Message "Start converting '$($Text)' as '$($TextType)' to ApiText value"
        $apiText = ""

        switch ($TextType) {
            "State" {
                switch ($Text) {
                    "Coming" { $apiText = "ON" }
                    "Leaving" { $apiText = "OFF" }
                    "StartPause" { $apiText = "PAUSE_START" }
                    "EndPause" { $apiText = "PAUSE_END" }
                    Default {
                        Stop-PSFFunction -Message "Unhandeled pattern for parameter Text. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
                    }
                }
            }

            "Type" {
                switch ($Text) {
                    "Work" { $apiText = "WORK" }
                    "Inhouse" { $apiText = "INHOUSE" }
                    "Errand" { $apiText = "ERRAND" }
                    "Vacation" { $apiText = "VACATION" }
                    "Illness" { $apiText = "ILLNESS" }
                    "PaidAbsence" { $apiText = "ABSENCE_PAID" }
                    "UnpaidAbsence" { $apiText = "ABSENCE_UNPAID" }
                    "Overtime" { $apiText = "OVERTIME" }
                    "Support" { $apiText = "DOCUMENTED_SUPPORT" }
                    Default {
                        Stop-PSFFunction -Message "Unhandeled pattern for parameter Text. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
                    }
                }
            }

            Default {
                Stop-PSFFunction -Message "Unhandeled pattern for parameter TextType. Developers mistake." -EnableException $true -Cmdlet $pscmdlet
            }
        }

        # Output
        Write-PSFMessage -Level Debug -Message "'$($Text)' as '$($TextType)' converted into ApiText value: $($apiText) done"
        $apiText
    }

    end {}
}
