#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root='C:\JIMEcosystem\JARVIS')

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$StateDir=Join-Path $Root 'reasoning'
$Trace=Join-Path $StateDir 'kaizen-trace.jsonl'
$Eval=Join-Path $StateDir 'kaizen-evals.jsonl'
$Ledger=Join-Path $Root 'sincro\ledger.jsonl'
$Memory=Join-Path $Root 'memory\MI-SEGUNDO-YO-CONVERSATIONS.jsonl'
$Rag=Join-Path $Root 'rag'
$Obs=Join-Path $Root 'Obsidian\JIMEcosystem-Vault\JARVIS'
@($StateDir,(Split-Path $Ledger -Parent),(Split-Path $Memory -Parent),$Rag,$Obs)|ForEach-Object{if(-not(Test-Path $_)){New-Item -ItemType Directory -Path $_ -Force|Out-Null}}
foreach($f in @($Trace,$Eval,$Ledger,$Memory)){if(-not(Test-Path $f)){New-Item -ItemType File -Path $f -Force|Out-Null}}

function J([object]$o){$o|ConvertTo-Json -Depth 16 -Compress}
function Append([string]$p,[object]$o){Add-Content -LiteralPath $p -Value (J $o) -Encoding utf8}
function Get-LocalModels(){try{$r=Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3;@($r.models|ForEach-Object{[string]$_.name})}catch{@()}}
function Pick-TextModel(){
  $m=@(Get-LocalModels)
  foreach($x in @('qwen3.5:latest','qwen3:latest','qwen2.5:7b','qwen2.5:3b','llama3.2:3b')){if($m -contains $x){return $x}}
  foreach($x in $m){if($x -notmatch '(?i)embed|nomic|moondream'){return $x}}
  return $null
}
function Ask-Local([string]$model,[string]$prompt,[int]$predict=700){
  $body=@{model=$model;prompt=$prompt;stream=$false;options=@{temperature=0.15;num_ctx=8192;num_predict=$predict}}|ConvertTo-Json -Depth 8
  $r=Invoke-RestMethod 'http://127.0.0.1:11434/api/generate' -Method Post -ContentType 'application/json; charset=utf-8' -Body $body -TimeoutSec 240
  [string]$r.response
}
function Search-Context([string]$q){
  $tokens=@($q.ToLower().Split(' ',[StringSplitOptions]::RemoveEmptyEntries)|Where-Object{$_.Length -ge 4}|Select-Object -Unique -First 10)
  $hits=[Collections.Generic.List[string]]::new();$targets=@()
  if(Test-Path $Rag){$targets+=Get-ChildItem $Rag -File -Recurse -EA SilentlyContinue|Select-Object -First 40}
  if(Test-Path $Obs){$targets+=Get-ChildItem $Obs -File -Recurse -EA SilentlyContinue|Select-Object -First 100}
  foreach($f in $targets){foreach($t in $tokens){if($hits.Count -ge 16){break};try{$m=Select-String -LiteralPath $f.FullName -SimpleMatch $t -EA SilentlyContinue|Select-Object -First 1;if($m){$hits.Add("[$($f.Name)] $($m.Line.Trim())")}}catch{}};if($hits.Count -ge 16){break}}
  $hits -join "`n"
}
function Try-Arithmetic([string]$message){
  $s=$message.Trim()
  if($s -match '^\s*(-?\d+(?:[\.,]\d+)?)\s*([+\-*/])\s*(-?\d+(?:[\.,]\d+)?)\s*\??\s*$'){
    $a=[double]($matches[1]-replace ',','.');$op=$matches[2];$b=[double]($matches[3]-replace ',','.')
    switch($op){'+'{$v=$a+$b};'-'{$v=$a-$b};'*'{$v=$a*$b};'/'{if($b -eq 0){return @{matched=$true;answer='No se puede dividir entre cero.'}};$v=$a/$b}}
    if([math]::Abs($v-[math]::Round($v)) -lt 1e-12){$txt=[string][int64][math]::Round($v)}else{$txt=$v.ToString([Globalization.CultureInfo]::InvariantCulture)}
    return @{matched=$true;answer=$txt}
  }
  @{matched=$false;answer=$null}
}
function Review-Deterministic([string]$question,[string]$answer){
  $issues=[Collections.Generic.List[string]]::new()
  if([string]::IsNullOrWhiteSpace($answer)){$issues.Add('EMPTY_ANSWER')}
  if($answer -match '(?i)el puente local de ejecución será el siguiente componente'){$issues.Add('BANNED_PLACEHOLDER')}
  if($answer.Length -gt 20 -and $question.Length -lt 8 -and $question -match '^\s*\d+\s*[+\-*/]\s*\d+'){$issues.Add('OVERANSWER_SIMPLE_MATH')}
  @{pass=($issues.Count -eq 0);issues=@($issues)}
}
function Invoke-OMNIKaizenReasoning{
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][string]$Message,
  [ValidateSet('TRIVIAL','NORMAL','HIGH','EXTREME')][string]$Level='HIGH',
  [string]$UserContext=''
 )
 $run=[guid]::NewGuid().ToString();$started=(Get-Date)
 $arith=Try-Arithmetic $Message
 if($arith.matched){
   $reply=[string]$arith.answer
   $r=Review-Deterministic $Message $reply
   Append $Trace ([ordered]@{run_id=$run;timestamp=(Get-Date).ToString('o');level='TRIVIAL';question=$Message;route='DETERMINISTIC_ARITHMETIC';review=$r;answer=$reply})
   return [ordered]@{reply=$reply;route='DETERMINISTIC_ARITHMETIC';verified=$r.pass;issues=$r.issues;run_id=$run}
 }
 $context=Search-Context $Message
 $model=Pick-TextModel
 if(-not $model){
   $reply='No hay un modelo local de texto operativo para razonar esta respuesta. He bloqueado una respuesta inventada y registrado el fallo para reparación.'
   Append $Trace ([ordered]@{run_id=$run;timestamp=(Get-Date).ToString('o');level=$Level;question=$Message;route='BLOCKED_NO_LOCAL_MODEL';answer=$reply})
   return [ordered]@{reply=$reply;route='BLOCKED_NO_LOCAL_MODEL';verified=$false;issues=@('NO_LOCAL_MODEL');run_id=$run}
 }
 $intentPrompt=@"
Devuelve SOLO JSON válido con estas claves: intent, direct_answer_required, requested_actions, constraints, must_not_do.
Interpreta exactamente lo que pide el usuario. No respondas todavía.
USUARIO: $Message
CONTEXTO_USUARIO: $UserContext
"@
 try{$intentRaw=Ask-Local $model $intentPrompt 350;$intent=$intentRaw|ConvertFrom-Json}catch{$intent=[ordered]@{intent=$Message;direct_answer_required=$true;requested_actions=@();constraints=@();must_not_do=@()}}
 $draftPrompt=@"
Eres OMNI-JIMMOSS FULL. Responde en español y directamente a la petición.
REGLAS: coste 0 primero; no inventar estados ni ingresos; usar contexto recuperado cuando sea relevante; no repetir plantillas; si algo no está verificado, decirlo; no revelar cadena de pensamiento.
INTENCIÓN: $($intent|ConvertTo-Json -Depth 6 -Compress)
CONTEXTO RAG/OBSIDIAN:
$context
PREGUNTA:
$Message
Genera sólo la respuesta candidata.
"@
 $draft=Ask-Local $model $draftPrompt 900
 $reviewCount=if($Level -eq 'EXTREME'){2}else{1}
 $reviews=@()
 for($i=1;$i -le $reviewCount;$i++){
  $reviewPrompt=@"
Actúa como revisor independiente. No reescribas la respuesta. Devuelve SOLO JSON con: pass(boolean), relevance(0-100), correctness(0-100), completeness(0-100), user_alignment(0-100), evidence(0-100), repetition(boolean), issues(array), correction_instructions(array).
Pregunta: $Message
Intención: $($intent|ConvertTo-Json -Depth 6 -Compress)
Respuesta candidata: $draft
Contexto disponible: $context
"@
  try{$rv=(Ask-Local $model $reviewPrompt 500)|ConvertFrom-Json}catch{$rv=[ordered]@{pass=$false;relevance=0;correctness=0;completeness=0;user_alignment=0;evidence=0;repetition=$false;issues=@('REVIEW_PARSE_FAILED');correction_instructions=@('Revisar respuesta')}}
  $reviews+=$rv
 }
 $det=Review-Deterministic $Message $draft
 $needsFix=(-not $det.pass) -or (@($reviews|Where-Object{-not $_.pass}).Count -gt 0)
 if($needsFix -or $Level -in @('HIGH','EXTREME')){
   $fixPrompt=@"
Reescribe la respuesta candidata para resolver TODOS los problemas detectados. Responde exactamente a la pregunta, sin explicar tu proceso interno. Si el usuario pidió ejecutar algo y no se ejecutó, indica el bloqueo exacto. No inventes hechos.
Pregunta: $Message
Intención: $($intent|ConvertTo-Json -Depth 6 -Compress)
Borrador: $draft
Revisiones: $($reviews|ConvertTo-Json -Depth 8 -Compress)
Chequeo determinista: $($det|ConvertTo-Json -Depth 6 -Compress)
Contexto: $context
Devuelve sólo la respuesta final.
"@
   $final=Ask-Local $model $fixPrompt 1000
 }else{$final=$draft}
 $finalDet=Review-Deterministic $Message $final
 $score=if($reviews.Count){[math]::Round((($reviews|Measure-Object relevance -Average).Average + ($reviews|Measure-Object correctness -Average).Average + ($reviews|Measure-Object completeness -Average).Average + ($reviews|Measure-Object user_alignment -Average).Average + ($reviews|Measure-Object evidence -Average).Average)/5,1)}else{0}
 $trace=[ordered]@{run_id=$run;timestamp=(Get-Date).ToString('o');duration_ms=[int]((Get-Date)-$started).TotalMilliseconds;level=$Level;model=$model;intent=$intent;review_summary=$reviews;deterministic_review=$finalDet;quality_score=$score;answer=$final}
 Append $Trace $trace
 Append $Ledger ([ordered]@{event_id=[guid]::NewGuid().ToString();timestamp=(Get-Date).ToString('o');source='OMNI-KAIZEN-REASONING';kind='answer_verified';state=$(if($finalDet.pass){'PASS'}else{'DEGRADED'});detail="run=$run level=$Level model=$model score=$score";cost_eur=0})
 return [ordered]@{reply=$final;route="KAIZEN:$model";verified=$finalDet.pass;quality_score=$score;issues=$finalDet.issues;run_id=$run}
}

if($MyInvocation.InvocationName -ne '.'){
 Write-Output 'OMNI-KAIZEN-REASONING-KERNEL loaded. Dot-source this file and call Invoke-OMNIKaizenReasoning.'
}
