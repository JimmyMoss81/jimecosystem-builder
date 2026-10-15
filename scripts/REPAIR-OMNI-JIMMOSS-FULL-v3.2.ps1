#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root="C:\JIMEcosystem\JARVIS")

$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function ED([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }
function SafeText([string]$p,[string]$c){ ED (Split-Path -Parent $p); [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }
function AddJsonlUnique([string]$Path,[string]$Id,[object]$Obj){
    ED (Split-Path -Parent $Path)
    if(-not(Test-Path -LiteralPath $Path)){ New-Item -ItemType File -Path $Path -Force | Out-Null }
    $exists = Select-String -LiteralPath $Path -Pattern $Id -SimpleMatch -Quiet -ErrorAction SilentlyContinue
    if(-not $exists){ Add-Content -LiteralPath $Path -Value ($Obj|ConvertTo-Json -Compress -Depth 12) -Encoding utf8 }
}

$UI="$Root\OMNI-JIMMOSS-FULL"
$Voice="$Root\voice"
$Reports="$Root\Reports"
$Ledger="$Root\sincro\ledger.jsonl"
$Rag="$Root\rag\JARVIS-KNOWLEDGE-SOURCES.jsonl"
$Tag="$Root\tag\knowledge-tags.jsonl"
$Config="$Root\config"
$Vault="$Root\Obsidian\JIMEcosystem-Vault\JARVIS\Conocimiento\Radar"
@($UI,$Voice,$Reports,$Config,$Vault,(Split-Path $Ledger -Parent),(Split-Path $Rag -Parent),(Split-Path $Tag -Parent)) | ForEach-Object { ED $_ }

$html=@'
<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>OMNI-JIMMOSS FULL</title><style>
:root{--bg:#212121;--panel:#171717;--line:#343434;--text:#ececec;--muted:#aaa;--input:#2f2f2f}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font-family:Segoe UI,Arial;height:100vh}.app{display:grid;grid-template-columns:260px 1fr;height:100vh}.side{background:var(--panel);border-right:1px solid var(--line);padding:18px}.brand{font-weight:700;font-size:18px;margin-bottom:16px}.nav button{display:block;width:100%;text-align:left;background:transparent;color:var(--text);border:0;padding:11px;border-radius:8px;margin:4px 0}.nav button:hover{background:#292929}.main{display:flex;flex-direction:column;min-width:0}.top{height:60px;border-bottom:1px solid var(--line);display:flex;align-items:center;gap:10px;padding:0 20px}.top select,.top button{background:#2b2b2b;color:var(--text);border:1px solid #454545;border-radius:8px;padding:8px}.chat{flex:1;overflow:auto;padding:28px max(22px,calc((100% - 820px)/2))}.msg{margin-bottom:22px;line-height:1.55}.who{font-size:12px;color:var(--muted);margin-bottom:5px}.composer{padding:16px max(20px,calc((100% - 860px)/2)) 22px}.box{display:flex;gap:8px;background:var(--input);border:1px solid #4a4a4a;border-radius:18px;padding:10px}textarea{flex:1;resize:none;background:transparent;color:var(--text);border:0;outline:0;min-height:48px;font:inherit;padding:8px}.btn{border:0;border-radius:10px;background:#3b3b3b;color:white;padding:10px 12px}.hint{font-size:12px;color:var(--muted);margin-top:8px}@media(max-width:800px){.app{grid-template-columns:1fr}.side{display:none}.chat{padding:20px}.composer{padding:12px}}
</style></head><body><div class="app"><aside class="side"><div class="brand">OMNI-JIMMOSS FULL</div><div class="nav"><button onclick="announce('Estado del sistema')">Estado</button><button onclick="announce('Segundo Yo')">Segundo Yo</button><button onclick="announce('Workers')">Workers</button><button onclick="announce('Agents')">Agents</button><button onclick="announce('Skills')">Skills</button><button onclick="announce('Radar IA')">Radar IA</button><button onclick="announce('Monetización')">Monetización</button></div></aside><section class="main"><div class="top"><strong>Chat accesible</strong><select id="voiceSelect" aria-label="Voz"></select><button onclick="testVoice()">Probar voz</button></div><main id="chat" class="chat" aria-live="polite"><div class="msg"><div class="who">OMNI-JIMMOSS</div><div>Interfaz tipo chat cargada. Puedes escribir o dictar. La voz usa las opciones que Edge y Windows expongan realmente en este equipo.</div></div></main><div class="composer"><div class="box"><button class="btn" onclick="dictate()" aria-label="Dictar">Micrófono</button><textarea id="input" placeholder="Escribe o dicta una orden..." aria-label="Mensaje"></textarea><button class="btn" onclick="sendMsg()" aria-label="Enviar">Enviar</button></div><div class="hint">Enter envía. Mayús+Enter crea una línea nueva. Edge-TTS externo queda fuera del arranque para que un fallo de red no bloquee la interfaz.</div></div></section></div><script>
const chat=document.getElementById('chat'),input=document.getElementById('input'),select=document.getElementById('voiceSelect');let voices=[];function loadVoices(){voices=speechSynthesis.getVoices();select.innerHTML='';let preferred=-1;voices.forEach((v,i)=>{const o=document.createElement('option');o.value=i;o.textContent=v.name+' — '+v.lang;select.appendChild(o);const n=(v.name+' '+v.lang).toLowerCase();if(preferred<0&&n.includes('es')&&(n.includes('natural')||n.includes('laura')||n.includes('hilda')||n.includes('elvira')||n.includes('ximena')||n.includes('paola')))preferred=i});if(preferred<0)preferred=voices.findIndex(v=>v.lang&&v.lang.toLowerCase().startsWith('es'));if(preferred>=0)select.value=preferred}speechSynthesis.onvoiceschanged=loadVoices;loadVoices();function speak(t){if(!('speechSynthesis'in window))return;speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(t),v=voices[Number(select.value)];if(v)u.voice=v;u.lang=v?.lang||'es-ES';speechSynthesis.speak(u)}function add(w,t){const d=document.createElement('div');d.className='msg';const a=document.createElement('div');a.className='who';a.textContent=w;const b=document.createElement('div');b.textContent=t;d.appendChild(a);d.appendChild(b);chat.appendChild(d);chat.scrollTop=chat.scrollHeight}function sendMsg(){const t=input.value.trim();if(!t)return;add('Tú',t);input.value='';const r='Orden recibida. El puente local de Mi Segundo Yo será el siguiente componente a conectar.';add('Mi Segundo Yo',r);speak(r)}function testVoice(){speak('Esta es la voz seleccionada para OMNI JIMMOSS FULL.')}function announce(t){add('Sistema',t);speak(t)}function dictate(){const R=window.SpeechRecognition||window.webkitSpeechRecognition;if(!R){add('Sistema','El dictado no está disponible en esta sesión.');return}const r=new R();r.lang='es-ES';r.interimResults=false;r.continuous=false;r.onresult=e=>{input.value=e.results[0][0].transcript;input.focus()};r.onerror=e=>add('Sistema','Dictado no disponible: '+e.error);r.start()}input.addEventListener('keydown',e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();sendMsg()}});
</script></body></html>
'@
SafeText "$UI\index.html" $html

$voiceInfo=[ordered]@{
 timestamp=(Get-Date).ToString('o')
 mode='BROWSER_WINDOWS_VOICES'
 edge_tts_cli=if(Get-Command edge-tts -ErrorAction SilentlyContinue){'DETECTED_BUT_NOT_CALLED'}else{'NOT_DETECTED'}
 openvoice_paths=@("$Root\OpenVoice","C:\OpenVoice","D:\IA\OpenVoice")|Where-Object{Test-Path $_}
 coqui_paths=@("$Root\CoquiTTS","C:\CoquiTTS","D:\IA\CoquiTTS")|Where-Object{Test-Path $_}
 note='No se llama al endpoint externo de Edge-TTS durante el arranque.'
}
$voiceInfo|ConvertTo-Json -Depth 8|Set-Content "$Voice\VOICE-INVENTORY-2026-10-16.json" -Encoding utf8

$launcher=@'
#Requires -Version 7.0
$p="C:\JIMEcosystem\JARVIS\OMNI-JIMMOSS-FULL\index.html"
if(-not(Test-Path -LiteralPath $p)){throw "No existe OMNI-JIMMOSS FULL"}
$u=[Uri]::new($p).AbsoluteUri
$e1="${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$e2="$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
if(Test-Path $e1){Start-Process $e1 -ArgumentList "--new-window",$u}
elseif(Test-Path $e2){Start-Process $e2 -ArgumentList "--new-window",$u}
else{Start-Process $u}
'@
SafeText "$Root\Start-OMNI-JIMMOSS-FULL.ps1" $launcher

$event='REPAIR-OMNI-JIMMOSS-FULL-2026-10-16-v32'
$entry=[ordered]@{event_id=$event;timestamp=(Get-Date).ToString('o');kind='UI_VOICE_LEDGER_REPAIR';state='PASS'}
AddJsonlUnique $Ledger $event $entry
AddJsonlUnique $Rag $event $entry
$tagId='TAG-OMNI-JIMMOSS-REPAIR-2026-10-16-v32'
$tagEntry=[ordered]@{id=$tagId;entity_id=$event;tags=@('accessibility','voice','ui','ledger','rag');status='REGISTERED'}
AddJsonlUnique $Tag $tagId $tagEntry

$report=[ordered]@{timestamp=(Get-Date).ToString('o');state='PASS';ui="$UI\index.html";launcher="$Root\Start-OMNI-JIMMOSS-FULL.ps1";voice_inventory="$Voice\VOICE-INVENTORY-2026-10-16.json";ledger=$Ledger;rag=$Rag;tag=$Tag}
$report|ConvertTo-Json -Depth 8|Set-Content "$Reports\OMNI-JIMMOSS-FULL-v3.2-REPAIR.json" -Encoding utf8

Write-Output ''
Write-Output 'OMNI-JIMMOSS FULL v3.2: PASS'
Write-Output 'Se ha eliminado el bloqueo por Edge-TTS 403.'
Write-Output 'Se ha corregido el registro en Ledger/RAG/TAG.'
Write-Output 'Abriendo interfaz...'
& "$Root\Start-OMNI-JIMMOSS-FULL.ps1"
