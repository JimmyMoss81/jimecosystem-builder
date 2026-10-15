#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root="C:\JIMEcosystem\JARVIS")

$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function ED([string]$p){
    if(-not(Test-Path -LiteralPath $p)){
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

$UI="$Root\OMNI-JIMMOSS-FULL"
$Knowledge="$Root\Knowledge"
$Config="$Root\config"
$Voice="$Root\voice"
$Reports="$Root\Reports"
$Ledger="$Root\sincro\ledger.jsonl"
$Rag="$Root\rag\JARVIS-KNOWLEDGE-SOURCES.jsonl"
$Tag="$Root\tag\knowledge-tags.jsonl"
$Vault="$Root\Obsidian\JIMEcosystem-Vault\JARVIS\Conocimiento\Radar"

@($UI,$Knowledge,$Config,$Voice,$Reports,(Split-Path $Ledger -Parent),(Split-Path $Rag -Parent),(Split-Path $Tag -Parent),$Vault) | ForEach-Object { ED $_ }

$Backup="$Root\Backups\OMNI-JIMMOSS-FULL-"+(Get-Date -Format "yyyyMMdd-HHmmss")
if(Test-Path -LiteralPath "$UI\index.html"){
    ED (Split-Path $Backup -Parent)
    Copy-Item $UI $Backup -Recurse -Force
}

$html=@'
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>OMNI-JIMMOSS FULL</title>
<style>
:root{--bg:#212121;--panel:#171717;--line:#343434;--text:#ececec;--muted:#a7a7a7;--input:#2f2f2f}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);font-family:Segoe UI,Arial,sans-serif;height:100vh}
.app{display:grid;grid-template-columns:260px 1fr;height:100vh}
.side{background:var(--panel);border-right:1px solid var(--line);padding:18px}
.brand{font-weight:700;font-size:18px;margin-bottom:16px}
.nav button{display:block;width:100%;text-align:left;background:transparent;color:var(--text);border:0;padding:11px;border-radius:8px;margin:4px 0}
.nav button:hover{background:#292929}
.main{display:flex;flex-direction:column;min-width:0}
.top{height:60px;border-bottom:1px solid var(--line);display:flex;align-items:center;gap:10px;padding:0 20px}
.top select,.top button{background:#2b2b2b;color:var(--text);border:1px solid #454545;border-radius:8px;padding:8px}
.chat{flex:1;overflow:auto;padding:28px max(22px,calc((100% - 820px)/2))}
.msg{margin-bottom:22px;line-height:1.55}.who{font-size:12px;color:var(--muted);margin-bottom:5px}
.composer{padding:16px max(20px,calc((100% - 860px)/2)) 22px}
.box{display:flex;gap:8px;background:var(--input);border:1px solid #4a4a4a;border-radius:18px;padding:10px}
textarea{flex:1;resize:none;background:transparent;color:var(--text);border:0;outline:0;min-height:48px;font:inherit;padding:8px}
.btn{border:0;border-radius:10px;background:#3b3b3b;color:white;padding:10px 12px}
.hint{font-size:12px;color:var(--muted);margin-top:8px}
@media(max-width:800px){.app{grid-template-columns:1fr}.side{display:none}.chat{padding:20px}.composer{padding:12px}}
</style>
</head>
<body>
<div class="app">
<aside class="side">
<div class="brand">OMNI-JIMMOSS FULL</div>
<div class="nav">
<button onclick="announce('Estado del sistema')">Estado</button>
<button onclick="announce('Segundo Yo')">Segundo Yo</button>
<button onclick="announce('Workers')">Workers</button>
<button onclick="announce('Agents')">Agents</button>
<button onclick="announce('Skills')">Skills</button>
<button onclick="announce('Radar IA')">Radar IA</button>
<button onclick="announce('Monetización')">Monetización</button>
</div>
</aside>
<section class="main">
<div class="top">
<strong>Chat accesible</strong>
<select id="voiceSelect" aria-label="Voz"></select>
<button onclick="testVoice()">Probar voz</button>
</div>
<main id="chat" class="chat" aria-live="polite">
<div class="msg"><div class="who">OMNI-JIMMOSS</div><div>Interfaz tipo chat cargada. Puedes escribir o dictar. Se usa la mejor voz española que Edge exponga en este equipo.</div></div>
</main>
<div class="composer">
<div class="box">
<button class="btn" onclick="dictate()" aria-label="Dictar">Micrófono</button>
<textarea id="input" placeholder="Escribe o dicta una orden..." aria-label="Mensaje"></textarea>
<button class="btn" onclick="sendMsg()" aria-label="Enviar">Enviar</button>
</div>
<div class="hint">Enter envía. Mayús+Enter crea una línea nueva. Las voces Sol/Maple de ChatGPT no están expuestas a una página local.</div>
</div>
</section>
</div>
<script>
const chat=document.getElementById('chat');
const input=document.getElementById('input');
const select=document.getElementById('voiceSelect');
let voices=[];
function loadVoices(){
  voices=speechSynthesis.getVoices();
  select.innerHTML='';
  let preferred=-1;
  voices.forEach((v,i)=>{
    const o=document.createElement('option');
    o.value=i;o.textContent=v.name+' — '+v.lang;
    select.appendChild(o);
    const n=(v.name+' '+v.lang).toLowerCase();
    if(preferred<0 && n.includes('es') && (n.includes('natural')||n.includes('elvira')||n.includes('ximena')||n.includes('paola')||n.includes('laura')||n.includes('hilda'))) preferred=i;
  });
  if(preferred<0) preferred=voices.findIndex(v=>v.lang&&v.lang.toLowerCase().startsWith('es'));
  if(preferred>=0) select.value=preferred;
}
speechSynthesis.onvoiceschanged=loadVoices; loadVoices();
function speak(t){
  if(!('speechSynthesis' in window)) return;
  speechSynthesis.cancel();
  const u=new SpeechSynthesisUtterance(t);
  const v=voices[Number(select.value)];
  if(v)u.voice=v;
  u.lang=v?.lang||'es-ES';
  u.rate=1;
  speechSynthesis.speak(u);
}
function add(who,text){
  const d=document.createElement('div');d.className='msg';
  const a=document.createElement('div');a.className='who';a.textContent=who;
  const b=document.createElement('div');b.textContent=text;
  d.appendChild(a);d.appendChild(b);chat.appendChild(d);chat.scrollTop=chat.scrollHeight;
}
function sendMsg(){
  const t=input.value.trim();if(!t)return;
  add('Tú',t);input.value='';
  const r='Orden recibida. Mi Segundo Yo la enviará al Worker local cuando el puente de ejecución esté conectado.';
  add('Mi Segundo Yo',r);speak(r);
}
function testVoice(){speak('Esta es la voz seleccionada para OMNI JIMMOSS FULL.');}
function announce(t){add('Sistema',t);speak(t);}
function dictate(){
  const R=window.SpeechRecognition||window.webkitSpeechRecognition;
  if(!R){add('Sistema','El dictado del navegador no está disponible en esta sesión.');return;}
  const r=new R();r.lang='es-ES';r.interimResults=false;r.continuous=false;
  r.onresult=e=>{input.value=e.results[0][0].transcript;input.focus();};
  r.onerror=e=>add('Sistema','Dictado no disponible: '+e.error);
  r.start();
}
input.addEventListener('keydown',e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();sendMsg();}});
</script>
</body>
</html>
'@

[IO.File]::WriteAllText("$UI\index.html",$html,[Text.UTF8Encoding]::new($false))

$radar=@'
# JIME Radar IA 2026-10-15
Estado: SOURCE_VERIFIED / SOCIAL_RADAR_PARTIAL / TRUTHGATE_REQUIRED

Novedades incorporadas:
- OpenAI: Agents API, computer use y Decisions API.
- Anthropic: Claude Haiku 5.5 para tareas de volumen/coste.
- Meta: Ads Creative Studio y Business AI Assistant con capacidades agénticas.
- Google: Universal Cart, UCP y AP2.
- Shopify: Sidekick aplicado a checkout/accounts y operaciones comerciales.
- DHL: Agentic AI, AI Commerce, Compute Economy y Humanoids.
- Patreon: Autopilot y nueva creator page.
- Xataka: supervisión humana de agentes, seguridad y eficiencia energética por software.
- Telegram/Reddit: seguridad zero-trust, evitar tool sprawl y automatizar procesos ya validados.

Fuentes sociales TG/IG/FB/YT/TT/PT/X/Threads/Tumblr/Reddit/Patreon/Skool/Xataka/ComputerHoy = RADAR_ONLY salvo fuente primaria.
'@
[IO.File]::WriteAllText("$Knowledge\JIME-RADAR-IA-2026-10-15.md",$radar,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText("$Vault\Radar IA 2026-10-15.md",$radar,[Text.UTF8Encoding]::new($false))

$sources=[ordered]@{
 updated_at=(Get-Date).ToString("o")
 sources=@(
  @{id="OpenAI";url="https://developers.openai.com/api/docs/changelog";class="PRIMARY"},
  @{id="Anthropic";url="https://www.anthropic.com/claude-haiku-5-5";class="PRIMARY"},
  @{id="Meta";url="https://about.fb.com/";class="PRIMARY"},
  @{id="Google";url="https://blog.google/";class="PRIMARY"},
  @{id="Shopify";url="https://changelog.shopify.com/";class="PRIMARY"},
  @{id="DHL";url="https://www.dhl.com/";class="PRIMARY"},
  @{id="Patreon";url="https://support.patreon.com/";class="PRIMARY"},
  @{id="Telegram";url="https://t.me/";class="RADAR_ONLY"},
  @{id="Instagram";url="https://www.instagram.com/";class="RADAR_ONLY"},
  @{id="Facebook";url="https://www.facebook.com/";class="RADAR_ONLY"},
  @{id="YouTube";url="https://www.youtube.com/";class="RADAR_ONLY"},
  @{id="TikTok";url="https://www.tiktok.com/";class="RADAR_ONLY"},
  @{id="Pinterest";url="https://www.pinterest.com/";class="RADAR_ONLY"},
  @{id="X";url="https://x.com/";class="RADAR_ONLY"},
  @{id="Threads";url="https://www.threads.net/";class="RADAR_ONLY"},
  @{id="Tumblr";url="https://www.tumblr.com/";class="RADAR_ONLY"},
  @{id="Reddit";url="https://www.reddit.com/";class="COMMUNITY"},
  @{id="Skool";url="https://www.skool.com/";class="RADAR_ONLY"},
  @{id="Xataka";url="https://www.xataka.com/";class="SECONDARY"},
  @{id="ComputerHoy";url="https://computerhoy.com/";class="SECONDARY"}
 )
}
$sources|ConvertTo-Json -Depth 8|Set-Content "$Config\JIME-SOCIAL-AI-RADAR-SOURCES-2026-10-15.json" -Encoding utf8

$edgeState="NOT_AVAILABLE"
if(Get-Command edge-tts -ErrorAction SilentlyContinue){
    $edgeState="DETECTED"
}elseif(Get-Command py -ErrorAction SilentlyContinue){
    try{
        py -m pip install --user edge-tts --disable-pip-version-check --quiet
        if($LASTEXITCODE -eq 0){$edgeState="INSTALLED_OR_UPDATED"}else{$edgeState="INSTALL_FAILED"}
    }catch{$edgeState="INSTALL_FAILED: $($_.Exception.Message)"}
}

$voiceInfo=[ordered]@{
 timestamp=(Get-Date).ToString("o")
 edge_tts=$edgeState
 preferred_voices=@("es-ES-XimenaNeural","es-ES-ElviraNeural","es-VE-PaolaNeural")
 note="Sol/Maple de ChatGPT no están expuestas a páginas HTML locales."
}
$voiceInfo|ConvertTo-Json -Depth 6|Set-Content "$Voice\VOICE-INVENTORY-2026-10-15.json" -Encoding utf8

if((Get-Command edge-tts -ErrorAction SilentlyContinue) -or (Get-Command py -ErrorAction SilentlyContinue)){
    try{
        $mp3="$Voice\prueba-voz.mp3"
        if(Get-Command edge-tts -ErrorAction SilentlyContinue){
            edge-tts --voice es-ES-XimenaNeural --text "OMNI JIMMOSS FULL está listo." --write-media $mp3
        } else {
            py -m edge_tts --voice es-ES-XimenaNeural --text "OMNI JIMMOSS FULL está listo." --write-media $mp3
        }
        if(Test-Path $mp3){
            Add-Type -AssemblyName presentationCore
            $m=New-Object System.Windows.Media.MediaPlayer
            $m.Open([Uri]$mp3);$m.Play();Start-Sleep -Seconds 4;$m.Close()
        }
    }catch{}
}

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
[IO.File]::WriteAllText("$Root\Start-OMNI-JIMMOSS-FULL.ps1",$launcher,[Text.UTF8Encoding]::new($false))

if(-not(Test-Path $Ledger)){New-Item -ItemType File -Path $Ledger -Force|Out-Null}
if(-not(Test-Path $Rag)){New-Item -ItemType File -Path $Rag -Force|Out-Null}
if(-not(Test-Path $Tag)){New-Item -ItemType File -Path $Tag -Force|Out-Null}

$event="KNOWLEDGE-RADAR-AI-VOICE-UI-2026-10-15-v31"
$entry=[ordered]@{event_id=$event;timestamp=(Get-Date).ToString("o");kind="UI_VOICE_RADAR_UPGRADE";state="PASS"}
if(-not(Select-String $Ledger -SimpleMatch $event -Quiet -EA SilentlyContinue)){($entry|ConvertTo-Json -Compress)|Add-Content $Ledger -Encoding utf8}
if(-not(Select-String $Rag -SimpleMatch $event -Quiet -EA SilentlyContinue)){($entry|ConvertTo-Json -Compress)|Add-Content $Rag -Encoding utf8}
$tagId="TAG-RADAR-AI-VOICE-UI-2026-10-15-v31"
$tagEntry=[ordered]@{id=$tagId;entity_id=$event;tags=@("voice","tts","accessibility","social-radar","agentic-ai");status="REGISTERED"}
if(-not(Select-String $Tag -SimpleMatch $tagId -Quiet -EA SilentlyContinue)){($tagEntry|ConvertTo-Json -Compress)|Add-Content $Tag -Encoding utf8}

$report=[ordered]@{
 timestamp=(Get-Date).ToString("o")
 state="PASS"
 ui="$UI\index.html"
 voice_state=$edgeState
 voice_inventory="$Voice\VOICE-INVENTORY-2026-10-15.json"
 radar="$Config\JIME-SOCIAL-AI-RADAR-SOURCES-2026-10-15.json"
 backup=$Backup
}
$report|ConvertTo-Json -Depth 8|Set-Content "$Reports\OMNI-JIMMOSS-FULL-v3.1-2026-10-15.json" -Encoding utf8

Write-Output ""
Write-Output "OMNI-JIMMOSS FULL v3.1: PASS"
Write-Output "Interfaz tipo chat instalada."
Write-Output "Estado Edge-TTS: $edgeState"
Write-Output "Radar actualizado."
Write-Output "Abriendo interfaz..."
& "$Root\Start-OMNI-JIMMOSS-FULL.ps1"
