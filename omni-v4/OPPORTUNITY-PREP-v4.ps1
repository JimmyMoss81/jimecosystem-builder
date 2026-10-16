#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root='C:\JIMEcosystem\JARVIS')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function ED([string]$p){if(-not(Test-Path -LiteralPath $p)){New-Item -ItemType Directory -Path $p -Force|Out-Null}}
$Ledger=Join-Path $Root 'sincro\ledger.jsonl';$Inbox=Join-Path $Root 'sol-worker\missions\inbox';$Out=Join-Path $Root 'business-hub\autonomy';$Offers=Join-Path $Root 'deliverables\monetization';$Report=Join-Path $Out 'latest-opportunity-cycle.md'
@((Split-Path $Ledger -Parent),$Inbox,$Out,$Offers)|%{ED $_};if(-not(Test-Path $Ledger)){New-Item -ItemType File -Path $Ledger -Force|Out-Null}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$id="OPP-$stamp"
$offerFiles=@(Get-ChildItem $Offers -File -Recurse -EA SilentlyContinue|Select-Object -First 20);$offerNames=@($offerFiles|%{$_.BaseName})
$priority=if($offerNames -match '49|AUDITOR|RUNTIME'){'Preparar el siguiente paso para una oferta de auditoría o servicio ya definida.'}else{'Convertir una capacidad existente en una oferta simple con entrega clara.'}
$suggestions=@($priority,'Preparar una lista corta de prospectos relevantes para revisión humana.','Comprobar que la página, la entrega y el método de cobro estén listos antes de atraer tráfico.','Preparar un entregable reusable para reducir tiempo de entrega.','Registrar únicamente resultados verificados.')
@"
# Ciclo autónomo de preparación de oportunidades
Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Prioridad
$priority

## Acciones sugeridas
$($suggestions|%{"- $_"}|Out-String)

## Ofertas detectadas
$($offerNames|%{"- $_"}|Out-String)

Regla: este worker prepara investigación, borradores y siguientes pasos. No publica, no envía mensajes, no compra, no cobra y no cambia cuentas por sí solo.
"@|Set-Content $Report -Encoding utf8
$mission=[ordered]@{schema_version=1;mission_id=$id;created_at=(Get-Date).ToString('o');owner='OPPORTUNITY-PREP';coordinator='MI-SEGUNDO-YO';action='business_hub_bootstrap';priority='high';payload=@{objective='Preparar siguiente oportunidad monetizable de coste cero para revisión';suggestions=$suggestions;report=$Report}}
$mission|ConvertTo-Json -Depth 10|Set-Content (Join-Path $Inbox "$id.json") -Encoding utf8
([ordered]@{event_id=[guid]::NewGuid().ToString();timestamp=(Get-Date).ToString('o');source='OPPORTUNITY-PREP';kind='opportunity_cycle';state='mission_queued';mission_id=$id;report=$Report;cost_eur=0}|ConvertTo-Json -Compress)|Add-Content $Ledger -Encoding utf8
Write-Output "OPPORTUNITY PREP: PASS";Write-Output "Mission: $id";Write-Output "Report: $Report"
