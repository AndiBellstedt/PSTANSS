[CmdletBinding()]
Param (
    [switch]
    $SkipTest,

    [string[]]
    $CommandPath = @("$global:testroot\..\functions"), #, "$global:testroot\..\internal\functions"

    [string]
    $ModuleName = "PSTANSS",

    [string]
    $ExceptionsFile = "$global:testroot\general\ModuleFunctionsWhatIfIntegrity.Exceptions.ps1"
)
if ($SkipTest) { return }
if (-not (Get-Module -Name "Refactor" -ErrorAction Ignore)) { throw 666, "Missing required PowerShell Module 'Refactor' for this test" }
. $ExceptionsFile

# Data preperation - get all commands and parse with AST
$allFiles = Get-ChildItem $CommandPath -Recurse -File | Where-Object Name -like "*.ps1" | Where-Object BaseName -notin $global:ModuleFunctionsWhatIfIntegrityTestExceptions
$commands = foreach ($file in $allFiles) {
    if (-not (Get-ReToken -Path $file.FullName -ProviderName Function)) { continue }
    if (-not (Get-ReToken -Path $file.FullName -ProviderName Command)) { continue }

    Write-PSFMessage -Level Important -Message $file.FullName
    $functionList = Read-ReScriptCommand -Path $file.FullName -ErrorAction Ignore
    $attributeAst = Read-ReAstComponent -Path $file.FullName -Select AttributeAst | Where-Object { $_.Text -match '^\[CmdletBinding' }
    $_supportsShouldProcess = "$($attributeAst.Ast.NamedArguments | Where-Object ArgumentName -like "SupportsShouldProcess" | Select-Object -ExpandProperty Argument)".ToString().Trim('$')
    if (-not $_supportsShouldProcess) { $_supportsShouldProcess = "false" }
    $supportsShouldProcess = ([bool]::Parse( $_supportsShouldProcess ))

    [PSCustomObject]@{
        Name                  = $file.BaseName
        File                  = $file
        FunctionList          = $functionList
        SupportsShouldProcess = $supportsShouldProcess
    }
}
$funtionNamesWithWhatIfSupport = $commands | Where-Object SupportsShouldProcess -eq $true


Describe "Test '$($ModuleName)' module functions on nested functions" {
    BeforeAll {
    }

    #$command = $commands | Out-GridView -OutputMode Single
    foreach ($command in $commands) {
        $commandName = $command.Name

        Context "Test function '$($commandName)' for nested module functions calls that support WhatIf behaviour (supportShouldProcess=`$true')" {

            $functionsToCheck = $command.FunctionList | Where-Object name -in $funtionNamesWithWhatIfSupport.Name

            foreach ($function in $functionsToCheck) {

                $function.parameters.keys | Where-Object { $_ -like "WhatIf" }

                It "Nested module function '$($function) in command '$($commandName) has WhatIf as a parameter" -TestCases { parameters = $function.parameters } {
                    $parameters.keys | Where-Object { $_ -like "WhatIf" } | Should -BeNullOrEmpty
                }
            }
        }
    }
}