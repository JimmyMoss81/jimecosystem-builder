#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root="C:\JIMEcosystem\JARVIS")

$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function Ensure-Dir([string]$Path){
    if(-not(Test-Path -LiteralPath $Path)){
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

$UI = Join-Path $Root "OMNI-JIMMOSS-FULL"
$Panel = Join-Path $UI "index.html"
$Launcher = Join-Path $Root "Start-OMNI-JIMMOSS-FULL-App.ps1"
$Reports = Join-Path $Root "Reports"
Ensure-Dir $UI
Ensure-Dir $Reports

# Copia de seguridad de la interfaz anterior.
if(Test-Path -LiteralPath $Panel){
    $BackupDir = Join-Path $Root ("Backups\OMNI-JIMMOSS-FULL-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    Ensure-Dir $BackupDir
    Copy-Item -LiteralPath $Panel -Destination (Join-Path $BackupDir "index.html") -Force
}

$html = @'
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>OMNI-JIMMOSS FULL</title>
<style>
:root{--bg:#212121;--side:#171717;--panel:#2f2f2f;--line:#343434;--text:#ececec;--muted:#a6a6a6}
*{box-sizing:border-box}
html,body{margin:0;height:100%;background:var(--bg);color:var(--text);font-family:Segoe UI,Arial,sans-serif}
.app{display:grid;grid-template-columns:260px 1fr;height:100vh}
.side{background:var(--side);border-right:1px solid var(--line);padding:16px}
.brand{font-size:18px;font-weight:700;margin:4px 0 18px}
.nav button{display:block;width:100%;text-align:left;border:0;background:transparent;color:var(--text);padding:12px;border-radius:8px;margin:3px 0}
.nav button:hover,.nav button:focus{background:#292929;outline:1px solid #555}
.main{display:flex;flex-direction:column;min-width:0}
.top{height:60px;border-bottom:1px solid var(--line);display:flex;align-items:center;gap:10px;padding:0 20px}
.top select,.top button{background:#2b2b2b;color:var(--text);border:1px solid #4a4a4a;border-radius:8px;padding:8px}
.chat{flex:1;overflow:auto;padding:30px max(22px,calc((100% - 820px)/2))}
.msg{margin-bottom:22px;line-height:1.55}.who{font-size:12px;color:var(--muted);margin-bottom:5px}
.composer{padding:16px max(20px,calc((100% - 860px)/2)) 22px}
.box{display:flex;gap:8px;background:var(--panel);border:1px solid #4b4b4b;border-radius:18px;padding:10px}
textarea{flex:1;resize:none;background:transparent;color:var(--text);border:0;outline:0;min-height:52px;max-height:180px;font:inherit;padding:8px}
.btn{border:0;border-radius:10px;background:#3b3b3b;color:white;padding:10px 12px}.hint{font-size:12px;color:var(--muted);margin-top:8px}
.status{font-size:12px;color:var(--muted);margin-left:auto}
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
<label><input id="speakOnStart" type="checkbox" checked> Hablar al iniciar</label>
<span id="voiceStatus" class="status" aria-live="polite">Cargando voces...</span>
</div>
<main id="chat" class="chat" aria-live="polite">
<div class="msg"><div class="who">OMNI-JIMMOSS</div><div>Interfaz accesible iniciada. Puedes escribir o dictar una orden.</div></div>
</main>
<div class="composer">
<div class="box">
<button class="btn" onclick="dictate()" aria-label="Dictar">Micrófono</button>
<textarea id="input" placeholder="Escribe o dicta una orden..." aria-label="Mensaje"></textarea>
<button class="btn" onclick="sendMsg()" aria-label="Enviar">Enviar</button>
</div>
<div class="hint">Enter envía. Mayús+Enter crea una línea nueva. La voz seleccionada queda dentro de las voces que Edge/Windows exponen realmente.</div>
</div>
</section>
</div>
<script>
const chat=document.getElementById('chat');
const input=document.getElementById('input');
const select=document.getElementById('voiceSelect');
const status=document.getElementById('voiceStatus');
const speakOnStart=document.getElementById('speakOnStart');
let voices=[];
let startupSpoken=false;

function choosePreferred(){
  const prefs=['microsoft laura - spanish (spain)','microsoft hilda','microsoft elvira','microsoft ximena','microsoft paola'];
  for(const p of prefs){
    const i=voices.findIndex(v=>(v.name||'').toLowerCase().includes(p));
    if(i>=0) return i;
  }
  let i=voices.findIndex(v=>((v.lang||'').toLowerCase()==='es-es') && (v.name||'').toLowerCase().includes('natural'));
  if(i>=0) return i;
  i=voices.findIndex(v=>(v.lang||'').toLowerCase().startsWith('es'));
  return i;
}

function loadVoices(){
  voices=window.speechSynthesis ? speechSynthesis.getVoices() : [];
  select.innerHTML='';
  voices.forEach((v,i)=>{
    const o=document.createElement('option');
    o.value=String(i);o.textContent=v.name+' — '+v.lang;select.appendChild(o);
  });
  const p=choosePreferred();
  if(p>=0) select.value=String(p);
  const v=voices[Number(select.value)];
  status.textContent=v ? ('Voz: '+v.name) : 'Sin voz disponible';
  if(v && speakOnStart.checked && !startupSpoken){
    setTimeout(()=>speakStartup(),700);
  }
}

function speakText(text){
  if(!window.speechSynthesis){status.textContent='Síntesis de voz no disponible';return false;}
  const v=voices[Number(select.value)];
  if(!v){status.textContent='No hay una voz seleccionada';return false;}
  speechSynthesis.cancel();
  const u=new SpeechSynthesisUtterance(text);
  u.voice=v;u.lang=v.lang||'es-ES';u.rate=1;u.volume=1;
  u.onstart=()=>{status.textContent='Hablando con '+v.name;};
  u.onend=()=>{status.textContent='Voz: '+v.name;};
  u.onerror=()=>{status.textContent='La voz no pudo reproducirse';};
  speechSynthesis.speak(u);
  return true;
}

function speakStartup(){
  if(startupSpoken) return;
  if(speakText('OMNI JIMMOSS FULL está listo. Mi Segundo Yo está preparado para recibir tus órdenes.')) startupSpoken=true;
}

function testVoice(){startupSpoken=true;speakText('Esta es la voz seleccionada para OMNI JIMMOSS FULL.');}
function add(who,text){const d=document.createElement('div');d.className='msg';const a=document.createElement('div');a.className='who';a.textContent=who;const b=document.createElement('div');b.textContent=text;d.append(a,b);chat.appendChild(d);chat.scrollTop=chat.scrollHeight;}
function announce(t){add('Sistema',t);speakText(t);}
function sendMsg(){const t=input.value.trim();if(!t)return;add('Tú',t);input.value='';const r='Orden recibida por Mi Segundo Yo. El puente local de ejecución será el siguiente componente que conectaremos.';add('Mi Segundo Yo',r);speakText(r);}
function dictate(){const R=window.SpeechRecognition||window.webkitSpeechRecognition;if(!R){add('Sistema','El dictado del navegador no está disponible en esta sesión.');speakText('El dictado no está disponible en esta sesión.');return;}const r=new R();r.lang='es-ES';r.interimResults=false;r.continuous=false;r.onresult=e=>{input.value=e.results[0][0].transcript;input.focus();};r.onerror=e=>add('Sistema','Dictado no disponible: '+e.error);r.start();}

if(window.speechSynthesis){speechSynthesis.onvoiceschanged=loadVoices;}
loadVoices();
setTimeout(loadVoices,400);
setTimeout(loadVoices,1200);

// Si Edge bloquea el habla automática, el primer gesto del usuario la desbloquea.
function unlockOnce(){if(!startupSpoken && speakOnStart.checked) speakStartup();}
document.addEventListener('pointerdown',unlockOnce,{once:true});
document.addEventListener('keydown',unlockOnce,{once:true});
select.addEventListener('change',()=>{const v=voices[Number(select.value)];status.textContent=v?('Voz: '+v.name):'Sin voz disponible';});
input.addEventListener('keydown',e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();sendMsg();}});
</script>
</body>
</html>
'@

[IO.File]::WriteAllText($Panel,$html,[Text.UTF8Encoding]::new($false))

$launcherText = @'
#Requires -Version 7.0
$ErrorActionPreference="Stop"
$Panel="C:\JIMEcosystem\JARVIS\OMNI-JIMMOSS-FULL\index.html"
if(-not(Test-Path -LiteralPath $Panel)){throw "No existe OMNI-JIMMOSS FULL: $Panel"}
$Uri=[Uri]::new($Panel).AbsoluteUri
$Edge1="${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$Edge2="$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
$Edge=$null
if(Test-Path -LiteralPath $Edge1){$Edge=$Edge1}elseif(Test-Path -LiteralPath $Edge2){$Edge=$Edge2}else{throw "Microsoft Edge no encontrado."}
Start-Process -FilePath $Edge -ArgumentList @("--app=$Uri","--start-maximized","--disable-features=msEdgeSidebarV2")
'@
[IO.File]::WriteAllText($Launcher,$launcherText,[Text.UTF8Encoding]::new($false))

# Accesos directos: Escritorio y menú Inicio. Atajo de teclado Ctrl+Alt+J.
$Pwsh="C:\Program Files\PowerShell\7\pwsh.exe"
if(Test-Path -LiteralPath $Pwsh){
    $Wsh=New-Object -ComObject WScript.Shell
    $Desktop=[Environment]::GetFolderPath('Desktop')
    $StartMenu=Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    foreach($ShortcutPath in @((Join-Path $Desktop "OMNI-JIMMOSS FULL.lnk"),(Join-Path $StartMenu "OMNI-JIMMOSS FULL.lnk"))){
        $S=$Wsh.CreateShortcut($ShortcutPath)
        $S.TargetPath=$Pwsh
        $S.Arguments='-NoProfile -ExecutionPolicy Bypass -File "C:\JIMEcosystem\JARVIS\Start-OMNI-JIMMOSS-FULL-App.ps1"'
        $S.WorkingDirectory=$Root
        $S.Description='OMNI-JIMMOSS FULL - interfaz accesible'
        $S.Hotkey='CTRL+ALT+J'
        $S.Save()
    }
}

$report=[ordered]@{
    timestamp=(Get-Date).ToString("o")
    state="PASS"
    panel=$Panel
    launcher=$Launcher
    mode="EDGE_APP_WINDOW_NO_BROWSER_CHROME"
    startup_voice="ENABLED_WITH_EDGE_WINDOWS_SPEECH_SYNTHESIS"
    preferred_voice="Microsoft Laura Spanish Spain when available"
    keyboard_shortcut="CTRL+ALT+J"
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $Reports "OMNI-JIMMOSS-FULL-v3.3.json") -Encoding utf8

Write-Output ""
Write-Output "OMNI-JIMMOSS FULL v3.3: PASS"
Write-Output "Modo aplicación instalado: sin pestañas ni barra de direcciones."
Write-Output "Voz al iniciar: activada."
Write-Output "Voz preferida: Microsoft Laura si está disponible."
Write-Output "Atajo: Ctrl+Alt+J"
Write-Output "Abriendo OMNI-JIMMOSS FULL..."

& $Launcher
