#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root='C:\JIMEcosystem\JARVIS')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$Runtime=Join-Path $Root 'MiSegundoYo\MI-SEGUNDO-YO-BRIDGE-v4.ps1'
$Launcher=Join-Path $Root 'Start-OMNI-JIMMOSS-FULL-v4.ps1'
$Report=Join-Path $Root 'Reports\OMNI-JIMMOSS-v4.1-PORT-REPAIR.json'
$Pwsh='C:\Program Files\PowerShell\7\pwsh.exe'
if(-not(Test-Path -LiteralPath $Runtime)){throw "No encuentro el runtime: $Runtime"}
if(-not(Test-Path -LiteralPath $Pwsh)){throw "No encuentro PowerShell 7: $Pwsh"}

function PortFree([int]$Port){return (@(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue).Count -eq 0)}
$Port=$null
foreach($p in 8767..8775){if(PortFree $p){$Port=$p;break}}
if(-not $Port){throw 'No hay puerto libre entre 8767 y 8775.'}

$launcherCode=@"
#Requires -Version 7.0
`$Root='C:\JIMEcosystem\JARVIS'
`$Runtime=Join-Path `$Root 'MiSegundoYo\MI-SEGUNDO-YO-BRIDGE-v4.ps1'
`$Port=$Port
`$url="http://127.0.0.1:`$Port/"
`$healthy=`$false
try{
  `$r=Invoke-WebRequest -Uri (`$url+'api/status') -UseBasicParsing -TimeoutSec 2
  if(`$r.StatusCode -eq 200 -and `$r.Content -match 'operational'){`$healthy=`$true}
}catch{}
if(-not `$healthy){
  Start-Process '$Pwsh' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"`$Runtime`"",'-Port',"`$Port") -WindowStyle Hidden
  1..30|ForEach-Object{
    Start-Sleep -Milliseconds 400
    try{
      `$r=Invoke-WebRequest -Uri (`$url+'api/status') -UseBasicParsing -TimeoutSec 2
      if(`$r.StatusCode -eq 200 -and `$r.Content -match 'operational'){`$healthy=`$true;return}
    }catch{}
  }
}
if(-not `$healthy){throw "Mi Segundo Yo no responde correctamente en `$url"}
`$edge1="`${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
`$edge2="`$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
if(Test-Path `$edge1){Start-Process `$edge1 -ArgumentList "--app=`$url"}
elseif(Test-Path `$edge2){Start-Process `$edge2 -ArgumentList "--app=`$url"}
else{Start-Process `$url}
"@
[IO.File]::WriteAllText($Launcher,$launcherCode,[Text.UTF8Encoding]::new($false))

$runtimeAction=New-ScheduledTaskAction -Execute $Pwsh -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$Runtime`" -Port $Port"
$logon=New-ScheduledTaskTrigger -AtLogOn
$principal=New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'JIME-MiSegundoYo-v4' -InputObject (New-ScheduledTask -Action $runtimeAction -Trigger $logon -Principal $principal -Settings $settings) -Force|Out-Null

# Arrancar y validar el runtime correcto antes de abrir nada.
& $Launcher
$rootCheck=Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 5
$statusCheck=Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/status" -TimeoutSec 5
if($rootCheck.StatusCode -ne 200 -or $rootCheck.Content -notmatch 'OMNI-JIMMOSS'){throw 'La raíz no está sirviendo la interfaz OMNI-JIMMOSS.'}
if([string]$statusCheck.status -ne 'operational'){throw 'El endpoint /api/status no está operativo.'}

$state=[ordered]@{timestamp=(Get-Date).ToString('o');state='PASS';old_port=8766;selected_port=$Port;launcher=$Launcher;runtime=$Runtime;root_http=$rootCheck.StatusCode;api_status=$statusCheck.status}
New-Item -ItemType Directory -Path (Split-Path $Report -Parent) -Force|Out-Null
$state|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $Report -Encoding utf8
Write-Output ''
Write-Output 'OMNI-JIMMOSS v4.1: PASS'
Write-Output "Puerto correcto de Mi Segundo Yo: $Port"
Write-Output "Interfaz: http://127.0.0.1:$Port/"
Write-Output 'Raiz HTML verificada y /api/status operativo.'
Write-Output "Informe: $Report"
