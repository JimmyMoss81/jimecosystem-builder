#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root='C:\JIMEcosystem\JARVIS')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function ED([string]$p){if(-not(Test-Path -LiteralPath $p)){New-Item -ItemType Directory -Path $p -Force|Out-Null}}
function DL([string]$url,[string]$dest){ED (Split-Path $dest -Parent);Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing; if(-not(Test-Path $dest)){throw "No se descargó $dest"}}
$Base='https://raw.githubusercontent.com/JimmyMoss81/jimecosystem-builder/main/omni-v4'
$UI=Join-Path $Root 'OMNI-JIMMOSS-FULL\index.html'
$Runtime=Join-Path $Root 'MiSegundoYo\MI-SEGUNDO-YO-BRIDGE-v4.ps1'
$Opportunity=Join-Path $Root 'Workers\OPPORTUNITY-PREP-v4.ps1'
$Launcher=Join-Path $Root 'Start-OMNI-JIMMOSS-FULL-v4.ps1'
$Report=Join-Path $Root 'Reports\OMNI-JIMMOSS-FULL-v4-INSTALL.json'
@((Split-Path $UI -Parent),(Split-Path $Runtime -Parent),(Split-Path $Opportunity -Parent),(Split-Path $Report -Parent))|%{ED $_}

Write-Output 'Instalando OMNI-JIMMOSS FULL v4...'
DL "$Base/index.html" $UI
DL "$Base/MI-SEGUNDO-YO-BRIDGE-v4.ps1" $Runtime
DL "$Base/OPPORTUNITY-PREP-v4.ps1" $Opportunity
Unblock-File $Runtime,$Opportunity -ErrorAction SilentlyContinue

$launcherCode=@'
#Requires -Version 7.0
$Root='C:\JIMEcosystem\JARVIS'
$Runtime=Join-Path $Root 'MiSegundoYo\MI-SEGUNDO-YO-BRIDGE-v4.ps1'
$Port=8766
$active=@(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue).Count -gt 0
if(-not $active){
  Start-Process 'C:\Program Files\PowerShell\7\pwsh.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$Runtime`"") -WindowStyle Hidden
  $ok=$false
  1..20|%{Start-Sleep -Milliseconds 500;if(@(Get-NetTCPConnection -LocalPort $Port -State Listen -EA SilentlyContinue).Count -gt 0){$ok=$true;return}}
  if(-not $ok){throw 'Mi Segundo Yo no abrió el puerto 8766.'}
}
$url='http://127.0.0.1:8766/'
$edge1="${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe";$edge2="$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
if(Test-Path $edge1){Start-Process $edge1 -ArgumentList "--app=$url"}
elseif(Test-Path $edge2){Start-Process $edge2 -ArgumentList "--app=$url"}
else{Start-Process $url}
'@
[IO.File]::WriteAllText($Launcher,$launcherCode,[Text.UTF8Encoding]::new($false))

$pwsh='C:\Program Files\PowerShell\7\pwsh.exe'
$runtimeAction=New-ScheduledTaskAction -Execute $pwsh -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$Runtime`""
$logon=New-ScheduledTaskTrigger -AtLogOn
$principal=New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'JIME-MiSegundoYo-v4' -InputObject (New-ScheduledTask -Action $runtimeAction -Trigger $logon -Principal $principal -Settings $settings) -Force|Out-Null

$oppAction=New-ScheduledTaskAction -Execute $pwsh -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$Opportunity`""
$oppTrigger=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Hours 4) -RepetitionDuration (New-TimeSpan -Days 3650)
Register-ScheduledTask -TaskName 'JIME-OpportunityPrep-v4' -InputObject (New-ScheduledTask -Action $oppAction -Trigger $oppTrigger -Principal $principal -Settings $settings) -Force|Out-Null

# Ejecuta una preparación inicial y abre la interfaz.
& $Opportunity | Out-Null
& $Launcher

$state=[ordered]@{timestamp=(Get-Date).ToString('o');state='PASS';ui=$UI;runtime=$Runtime;opportunity_worker=$Opportunity;launcher=$Launcher;runtime_task='JIME-MiSegundoYo-v4';opportunity_task='JIME-OpportunityPrep-v4';port=8766}
$state|ConvertTo-Json -Depth 8|Set-Content $Report -Encoding utf8
Write-Output ''
Write-Output 'OMNI-JIMMOSS FULL v4: PASS'
Write-Output 'Mi Segundo Yo: runtime local conectado.'
Write-Output 'RAG, memoria persistente, Ledger, Obsidian y Sol-Worker: integrados por el runtime.'
Write-Output 'Preparación autónoma de oportunidades: cada 4 horas.'
Write-Output 'Interfaz: http://127.0.0.1:8766/'
Write-Output "Informe: $Report"
