#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root='C:\JIMEcosystem\JARVIS',[int]$Port=8770)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function ED([string]$p){if(-not(Test-Path -LiteralPath $p)){New-Item -ItemType Directory -Path $p -Force|Out-Null}}
function J([object]$o){$o|ConvertTo-Json -Depth 16 -Compress}

$Kernel=Join-Path $Root 'reasoning\OMNI-KAIZEN-REASONING-KERNEL.ps1'
$UI=Join-Path $Root 'OMNI-JIMMOSS-FULL\index.html'
$SolInbox=Join-Path $Root 'sol-worker\missions\inbox'
$Log=Join-Path $Root 'logs\MI-SEGUNDO-YO-BRIDGE-v5.log'
$State=Join-Path $Root 'reasoning\runtime-v5.json'
@((Split-Path $Kernel -Parent),(Split-Path $Log -Parent),$SolInbox)|ForEach-Object{ED $_}
if(-not(Test-Path $Kernel)){throw "Falta el kernel de razonamiento: $Kernel"}
. $Kernel

function Log([string]$m){Add-Content -LiteralPath $Log -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m" -Encoding utf8}
function Queue-Mission([string]$objective){
 $id='OMNI-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff')
 $p=Join-Path $SolInbox "$id.json"
 [ordered]@{schema_version=1;mission_id=$id;created_at=(Get-Date).ToString('o');owner='MI-SEGUNDO-YO';coordinator='OMNI-JIMMOSS-FULL';action='business_hub_bootstrap';priority='high';payload=@{objective=$objective;cost_policy='ZERO_FIRST'}}|ConvertTo-Json -Depth 10|Set-Content -LiteralPath $p -Encoding utf8
 return $id
}
function Level-For([string]$m){
 if($m -match '^\s*-?\d+(?:[\.,]\d+)?\s*[+\-*/]\s*-?\d+(?:[\.,]\d+)?\s*\??\s*$'){return 'TRIVIAL'}
 if($m.Length -gt 700 -or $m -match '(?i)audita|investiga|compara|estrategia|arquitectura|razonamiento extremo|proyecto|negocio'){return 'EXTREME'}
 if($m.Length -gt 180 -or $m -match '(?i)verifica|corrige|plan|monetiz|venta|cliente|repara'){return 'HIGH'}
 return 'NORMAL'
}

$listener=[Net.HttpListener]::new();$prefix="http://127.0.0.1:$Port/";$listener.Prefixes.Add($prefix)
try{$listener.Start()}catch{throw "No pude abrir $prefix : $($_.Exception.Message)"}
[ordered]@{status='operational';port=$Port;kernel='OMNI-KAIZEN-REASONING';started_at=(Get-Date).ToString('o')}|ConvertTo-Json|Set-Content $State -Encoding utf8
Log "v5 iniciado en $prefix"

while($listener.IsListening){
 $ctx=$listener.GetContext();$req=$ctx.Request;$res=$ctx.Response
 try{
  $path=$req.Url.AbsolutePath
  if($req.HttpMethod -eq 'GET' -and $path -eq '/'){
    if(-not(Test-Path $UI)){throw "No existe UI: $UI"}
    $b=[IO.File]::ReadAllBytes($UI);$res.ContentType='text/html; charset=utf-8';$res.OutputStream.Write($b,0,$b.Length)
  }
  elseif($req.HttpMethod -eq 'GET' -and $path -eq '/api/status'){
    $model=Pick-TextModel
    $body=J ([ordered]@{status='operational';version='v5';reasoning_kernel='OMNI-KAIZEN-REASONING';local_model=$model;ledger=(Test-Path (Join-Path $Root 'sincro\ledger.jsonl'));rag=(Test-Path (Join-Path $Root 'rag'));obsidian=(Test-Path (Join-Path $Root 'Obsidian'));sol_worker=(Test-Path $SolInbox)})
    $b=[Text.Encoding]::UTF8.GetBytes($body);$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length)
  }
  elseif($req.HttpMethod -eq 'POST' -and $path -eq '/api/chat'){
    $sr=[IO.StreamReader]::new($req.InputStream,$req.ContentEncoding);$raw=$sr.ReadToEnd();$o=$raw|ConvertFrom-Json;$msg=[string]$o.message
    $level=Level-For $msg
    $r=Invoke-OMNIKaizenReasoning -Message $msg -Level $level
    $mission=$null
    if($msg -match '(?i)ingres|monetiz|venta|cliente|captaci|publica|trabaj'){$mission=Queue-Mission $msg}
    $body=J ([ordered]@{reply=$r.reply;route=$r.route;verified=$r.verified;quality_score=$r.quality_score;issues=$r.issues;run_id=$r.run_id;reasoning_level=$level;mission_id=$mission})
    $b=[Text.Encoding]::UTF8.GetBytes($body);$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length)
  }
  elseif($req.HttpMethod -eq 'POST' -and $path -eq '/api/revenue'){
    $id=Queue-Mission 'Preparar siguiente acción monetizable verificable a coste cero'
    $body=J @{message="Misión creada: $id";mission_id=$id};$b=[Text.Encoding]::UTF8.GetBytes($body);$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length)
  }
  else{$res.StatusCode=404}
 }catch{$res.StatusCode=500;$b=[Text.Encoding]::UTF8.GetBytes((J @{error=$_.Exception.Message}));$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length);Log "ERROR $($_.Exception.Message)"}
 finally{$res.OutputStream.Close()}
}
