param([string]$Godot = "godot")
$ErrorActionPreference = "Stop"
$projectPath = Split-Path $PSScriptRoot -Parent
foreach ($suite in @("test_rules", "test_balance", "test_transport")) {
    $result = & $Godot --headless --path $projectPath --script "res://tests/$suite.gd" 2>&1
    $result | Write-Output
    if ($LASTEXITCODE -ne 0 -or ($result -match 'SCRIPT ERROR:|FAIL:')) { throw "$suite failed" }
}
