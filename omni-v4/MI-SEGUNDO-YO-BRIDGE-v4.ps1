#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root='C:\JIMEcosystem\JARVIS',[int]$Port=8766)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function ED([string]$p){if(-not(Test-Path -LiteralPath $p)){New-Item -ItemType Directory -Path $p -Force|Out-Null}}
$UI=Join-Path $Root 'OMNI-JIMMOSS-FULL\index.html'
$Memory=Join-Path $Root 'memory\MI-SEGUNDO-YO-CONVERSATIONS.jsonl'
$Ledger=Join-Path $Root 'sincro\ledger.jsonl'
$RagDir=Join-Path $Root 'rag'
$Obs=Join-Path $Root 'Obsidian\JIMEcosystem-Vault\JARVIS\Mi Segundo Yo'
$SolInbox=Join-Path $Root 'sol-worker\missions\inbox'
$SolResults=Join-Path $Root 'sol-worker\missions\results'
$Business=Join-Path $Root 'business-hub\autonomy'
$Suggestions=Join-Path $Business 'suggestions.json'
$ProviderRegistry=Join-Path $Root 'config\MI-SEGUNDO-YO-PROVIDERS.json'
$Log=Join-Path $Root 'logs\MI-SEGUNDO-YO-BRIDGE.log'
@((Split-Path $Memory -Parent),(Split-Path $Ledger -Parent),$RagDir,$Obs,$SolInbox,$SolResults,$Business,(Split-Path $ProviderRegistry -Parent),(Split-Path $Log -Parent))|%{ED $_}
if(-not(Test-Path $Ledger)){New-Item -ItemType File -Path $Ledger -Force|Out-Null}
if(-not(Test-Path $Memory)){New-Item -ItemType File -Path $Memory -Force|Out-Null}

function J([object]$o){$o|ConvertTo-Json -Depth 12 -Compress}
function Log([string]$m){Add-Content -LiteralPath $Log -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m" -Encoding utf8}
function Ledger([string]$kind,[string]$state,[string]$detail,[object]$artifacts=@()){
  $e=[ordered]@{event_id=[guid]::NewGuid().ToString();timestamp=(Get-Date).ToString('o');source='MI-SEGUNDO-YO';kind=$kind;state=$state;detail=$detail;artifacts=@($artifacts);cost_eur=0}
  Add-Content -LiteralPath $Ledger -Value (J $e) -Encoding utf8
}
function Persist([string]$role,[string]$text){
  $e=[ordered]@{timestamp=(Get-Date).ToString('o');role=$role;text=$text}
  Add-Content -LiteralPath $Memory -Value (J $e) -Encoding utf8
  $day=Join-Path $Obs ("$(Get-Date -Format 'yyyy-MM-dd') Conversaciones.md")
  Add-Content -LiteralPath $day -Value ("`n### $(Get-Date -Format 'HH:mm:ss') $role`n$text`n") -Encoding utf8
}
function Tail([string]$p,[int]$n=20){if(Test-Path $p){return ((Get-Content -LiteralPath $p -Tail $n -ErrorAction SilentlyContinue)-join "`n")}return ''}
function GetLocalModels(){try{$r=Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3;return @($r.models|%{[string]$_.name})}catch{return @()}}
function PickModel(){
 $m=@(GetLocalModels)
 foreach($x in @('qwen2.5:7b','qwen2.5:3b','llama3.2:3b','llama3.2:latest','tinyllama:latest')){if($m -contains $x){return $x}}
 foreach($x in $m){if($x -notmatch '(?i)embed|nomic|moondream'){return $x}}
 return $null
}
function AskOllama([string]$model,[string]$prompt){
 $b=@{model=$model;prompt=$prompt;stream=$false;options=@{temperature=.25;num_ctx=4096;num_predict=800}}|ConvertTo-Json -Depth 8
 $r=Invoke-RestMethod 'http://127.0.0.1:11434/api/generate' -Method Post -ContentType 'application/json; charset=utf-8' -Body $b -TimeoutSec 180
 return [string]$r.response
}
function SearchKnowledge([string]$q){
 $tokens=@($q.ToLower().Split(' ',[StringSplitOptions]::RemoveEmptyEntries)|?{$_.Length -ge 4}|Select-Object -Unique -First 8)
 $hits=[Collections.Generic.List[string]]::new()
 $targets=@()
 if(Test-Path $RagDir){$targets+=Get-ChildItem $RagDir -File -Recurse -EA SilentlyContinue|Select-Object -First 30}
 if(Test-Path (Split-Path $Obs -Parent)){$targets+=Get-ChildItem (Split-Path $Obs -Parent) -Filter '*.md' -File -Recurse -EA SilentlyContinue|Select-Object -First 80}
 foreach($f in $targets){
  if($hits.Count -ge 12){break}
  try{
   foreach($t in $tokens){
    $ms=Select-String -LiteralPath $f.FullName -SimpleMatch $t -EA SilentlyContinue|Select-Object -First 2
    foreach($m in $ms){$hits.Add("[$($f.Name)] $($m.Line.Trim())");if($hits.Count -ge 12){break}}
   }
  }catch{}
 }
 return ($hits -join "`n")
}
function ProviderState(){
 $files=@(Get-ChildItem $Root -File -Recurse -EA SilentlyContinue|Select-Object -First 5000)
 function D([string]$name){if($files.FullName -match [regex]::Escape($name)){'DISCOVERED'}else{'UNVERIFIED'}}
 $p=[ordered]@{
  updated_at=(Get-Date).ToString('o')
  providers=@(
   @{id='Ollama';state=$(if((GetLocalModels).Count){'AVAILABLE'}else{'UNAVAILABLE'});mode='LOCAL_FREE'},
   @{id='Sol-Worker';state=$(if(Test-Path $SolInbox){'AVAILABLE'}else{'UNAVAILABLE'});mode='LOCAL'},
   @{id='OMNIROUTE';state=$(try{(Invoke-WebRequest 'http://127.0.0.1:8765/health' -TimeoutSec 2 -UseBasicParsing).StatusCode;if($?){'AVAILABLE'}else{'UNVERIFIED'}}catch{'UNVERIFIED'});mode='LOCAL'},
   @{id='ChatGPT/OpenAI';state=$(if($env:OPENAI_API_KEY){'CONFIGURED_COST_GATED'}else{'NO_API_KEY'});mode='REMOTE'},
   @{id='Gemini';state=$(if($env:GEMINI_API_KEY -or $env:GOOGLE_API_KEY){'CONFIGURED_COST_GATED'}else{'NO_API_KEY'});mode='REMOTE'},
   @{id='NotebookLM';state='KNOWLEDGE_SOURCE_ONLY';mode='NO_SUPPORTED_LOCAL_RUNTIME'},
   @{id='Hermes Agent';state=(D 'Hermes');mode='DETECT_ONLY'},
   @{id='Mythos 5.1';state=(D 'Mythos');mode='DETECT_ONLY'},
   @{id='Fable 5.1';state=(D 'Fable');mode='DETECT_ONLY'},
   @{id='Opus 5';state=(D 'Opus 5');mode='DETECT_ONLY'},
   @{id='Jev';state=(D 'Jev');mode='UNVERIFIED_ALIAS'}
  )
 }
 $p|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $ProviderRegistry -Encoding utf8
 return $p
}
function QueueMission([string]$action,[hashtable]$payload,[string]$priority='high'){
 $id='MSY-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff')
 $m=[ordered]@{schema_version=1;mission_id=$id;created_at=(Get-Date).ToString('o');owner='MI-SEGUNDO-YO';coordinator='OMNI-JIMMOSS';action=$action;priority=$priority;payload=$payload}
 $p=Join-Path $SolInbox "$id.json";$m|ConvertTo-Json -Depth 12|Set-Content -LiteralPath $p -Encoding utf8
 Ledger 'mission_queued' 'queued' "$action / $id" @($p)
 return $id
}
function RevenueSuggestions(){
 $base=@(
  'Cerrar la Auditoría Express IA de 49 €: verificar URL pública, método de cobro y entrega antes de captar tráfico.',
  'Preparar una lista corta de prospectos reales para Auditoría IA, sin spam, con problema observable y mensaje personalizado.',
  'Convertir FactorÍA en un pack vendible: vídeo corto + voz + traducción + subtítulos + derivados multicanal.',
  'Revisar JimInCruise para detectar una acción de captación cualificada que pueda ejecutarse hoy a coste cero.',
  'Revisar ofertas de trabajo/microtareas verificables y priorizar una solicitud que pueda completarse hoy.'
 )
 [ordered]@{updated_at=(Get-Date).ToString('o');suggestions=$base}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $Suggestions -Encoding utf8
 return $base
}
function BuildReply([string]$message){
 Persist 'USER' $message
 $knowledge=SearchKnowledge $message
 $mem=Tail $Memory 10
 $led=Tail $Ledger 12
 $model=PickModel
 $route='LOCAL_RULES'
 $queued=$null
 if($message -match '(?i)ingres|monetiz|venta|cliente|trabaj'){$queued=QueueMission 'business_hub_bootstrap' @{objective=$message;source='OMNI-JIMMOSS-v4'} 'critical'}
 elseif($message -match '(?i)repar|estado|stack'){$queued=QueueMission 'repair_stack_links' @{objective=$message} 'high'}
 elseif($message -match '(?i)sincron|obsidian|rag|memoria|conocimiento'){$queued=QueueMission 'sync_knowledge' @{objective=$message} 'normal'}
 if($model){
  $route="OLLAMA:$model"
  $prompt=@"
Eres Mi Segundo Yo dentro de JIMEcosystem. Responde en español, de forma concreta y ejecutiva. No digas frases vacías como 'el puente será el siguiente componente'. Usa el contexto real. Si una tarea ya se ha puesto en cola, dilo con su identificador. Prioriza coste cero y monetización verificable. No afirmes ventas o conexiones no demostradas. Acciones externas sensibles requieren aprobación.

MENSAJE:
$message

CONOCIMIENTO RECUPERADO:
$knowledge

MEMORIA RECIENTE:
$mem

LEDGER RECIENTE:
$led

MISIÓN ENCOLADA:
$queued
"@
  try{$reply=AskOllama $model $prompt}catch{$reply="He procesado la orden localmente. Ruta: $route. " + $(if($queued){"Misión encolada: $queued."}else{'No fue necesario crear misión.'})}
 }else{
  $reply="He procesado la orden con los componentes locales disponibles."
  if($knowledge){$reply+=" Encontré contexto en RAG/Obsidian relacionado con tu petición."}
  if($queued){$reply+=" He creado la misión $queued para Sol-Worker."}
  else{$reply+=" No hay un modelo Ollama de texto disponible ahora mismo; no inventaré una respuesta de IA."}
 }
 Persist 'ASSISTANT' $reply
 Ledger 'chat' 'completed' $route @($(if($queued){$queued}else{''}))
 return @{reply=$reply;route=$route;mission_id=$queued}
}

$null=ProviderState
$null=RevenueSuggestions
$listener=[Net.HttpListener]::new();$prefix="http://127.0.0.1:$Port/";$listener.Prefixes.Add($prefix)
try{$listener.Start()}catch{throw "No pude abrir $prefix : $($_.Exception.Message)"}
Log "Runtime iniciado en $prefix"
Ledger 'runtime' 'started' $prefix
while($listener.IsListening){
 $ctx=$listener.GetContext();$req=$ctx.Request;$res=$ctx.Response
 try{
  $path=$req.Url.AbsolutePath
  if($req.HttpMethod -eq 'GET' -and $path -eq '/'){
   $bytes=[IO.File]::ReadAllBytes($UI);$res.ContentType='text/html; charset=utf-8';$res.OutputStream.Write($bytes,0,$bytes.Length)
  }elseif($req.HttpMethod -eq 'GET' -and $path -eq '/api/status'){
   $p=ProviderState;$m=PickModel;$body=J ([ordered]@{status='operational';local_model=$m;providers=$p.providers;greeting='Mi Segundo Yo está conectado al runtime local, memoria persistente, RAG, Ledger, Obsidian y Sol-Worker.'})
   $b=[Text.Encoding]::UTF8.GetBytes($body);$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length)
  }elseif($req.HttpMethod -eq 'GET' -and $path -eq '/api/suggestions'){
   $s=RevenueSuggestions;$body=J @{suggestions=$s};$b=[Text.Encoding]::UTF8.GetBytes($body);$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length)
  }elseif($req.HttpMethod -eq 'POST' -and $path -eq '/api/revenue'){
   $id=QueueMission 'business_hub_bootstrap' @{objective='Generar progreso monetizable coste cero y preparar siguiente acción verificable';trigger='UI'} 'critical'
   $body=J @{message="He creado la misión $id para Sol-Worker. Preparará trabajo local de monetización; publicaciones, pagos y envíos externos permanecen sujetos a autorización."};$b=[Text.Encoding]::UTF8.GetBytes($body);$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length)
  }elseif($req.HttpMethod -eq 'POST' -and $path -eq '/api/chat'){
   $sr=[IO.StreamReader]::new($req.InputStream,$req.ContentEncoding);$raw=$sr.ReadToEnd();$o=$raw|ConvertFrom-Json;$r=BuildReply ([string]$o.message);$body=J $r;$b=[Text.Encoding]::UTF8.GetBytes($body);$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length)
  }else{$res.StatusCode=404}
 }catch{$res.StatusCode=500;$b=[Text.Encoding]::UTF8.GetBytes((J @{error=$_.Exception.Message}));$res.ContentType='application/json';$res.OutputStream.Write($b,0,$b.Length);Log "ERROR $($_.Exception.Message)"}
 finally{$res.OutputStream.Close()}
}
