:; "./tools/scripts/getcompiler.sh" "14.2.0" && "./tools/scripts/getedcre.sh"; exit;
@ECHO Off
PowerShell -ExecutionPolicy Bypass -file "./tools/scripts/getcompiler.ps1" "14.2.0"
PowerShell -ExecutionPolicy Bypass -file "./tools/scripts/getedcre.ps1"