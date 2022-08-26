$runspaceName = "TANSS.LookupValidation"
$ScriptBlock = [System.Management.Automation.ScriptBlock]::Create( (Get-Content "$($script:ModuleRoot)\internal\scripts\Expand-TANSSCacheData.ps1" -Raw) )

if (Get-PSFRunspace -Name $runspaceName) {
    [TANSS.Cache]::StopValidationRunspace = $true
    Get-PSFRunspace -Name $runspaceName | Stop-PSFRunspace
}

Register-PSFRunspace -Name $runspaceName -ScriptBlock $ScriptBlock

[TANSS.Cache]::StopValidationRunspace = $false
Start-PSFRunspace -Name $runspaceName
