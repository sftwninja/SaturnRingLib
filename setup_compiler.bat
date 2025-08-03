:; "./tools/scripts/getcompiler.sh" "14.2.0" && "./tools/scripts/getedcre.sh" "v1.1.0"; exit;
@ECHO Off
PowerShell -ExecutionPolicy Bypass -file "./tools/scripts/getcompiler.ps1" "14.2.0"
PowerShell -ExecutionPolicy Bypass -file "./tools/scripts/getedcre.ps1" "v1.1.0"