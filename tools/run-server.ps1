param([string]$Godot = "godot", [int]$Port = 9080, [string]$BindAddress = "127.0.0.1")
$env:PORT = "$Port"
$env:BIND_ADDRESS = $BindAddress
& $Godot --headless --path (Split-Path $PSScriptRoot -Parent) -- --server
exit $LASTEXITCODE
