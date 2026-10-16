#Requires -Version 7.0
<#
OMNI-JIMMOSS FULL - Revenue Sprint v1
Objetivo: convertir capacidades existentes en acciones de ingreso verificables sin coste de acceso.
No publica, cobra ni usa credenciales por sí solo. Prepara activos, cola y evidencias para ejecución autorizada.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = 'C:\JIMEcosystem\JARVIS'
$Revenue = Join-Path $Root 'RevenueSprint'
$Offers = Join-Path $Revenue 'Offers'
$Evidence = Join-Path $Revenue 'Evidence'
$Queue = Join-Path $Revenue 'revenue-action-queue.jsonl'
$Ledger = Join-Path $Root 'sincro\ledger.jsonl'
$Report = Join-Path $Revenue 'REVENUE-SPRINT-STATUS.json'

@($Revenue,$Offers,$Evidence) | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }

function Add-JsonLine {
    param([string]$Path,[hashtable]$Data)
    $Data['timestamp'] = (Get-Date).ToString('o')
    ($Data | ConvertTo-Json -Compress -Depth 8) | Add-Content -LiteralPath $Path -Encoding utf8
}

# Regla de verdad: no declarar ingreso hasta tener evidencia de pago.
$policy = @'
OMNI-JIMMOSS FULL - REVENUE TRUTH GATE
1. Una oportunidad no es un ingreso.
2. Una solicitud enviada no es una venta.
3. Un cliente interesado no es un cobro.
4. Solo PAYMENT_VERIFIED permite registrar ingreso.
5. Coste de acceso obligatorio > 0 EUR => BLOCKED_BY_COST0, salvo autorizacion expresa del usuario.
6. No usar identidades falsas, credenciales ajenas ni eludir limites de plataformas.
'@
[IO.File]::WriteAllText((Join-Path $Revenue 'REVENUE-TRUTH-GATE.txt'),$policy,[Text.UTF8Encoding]::new($false))

# Oferta 1: FactorIA / video IA. Se empaqueta sin inventar portfolio ni resultados.
$videoOffer = @'
FACTORIA - PACK DE VIDEO IA PARA REDES
Entregable base:
- video vertical 30-60 s
- subtitulos
- limpieza de audio
- adaptacion para Reels/TikTok/Shorts
- una ronda de cambios

Prueba comercial inicial:
- usar solo material propio, licenciado o aportado por el cliente
- no prometer conversiones ni resultados economicos
- acordar precio y plazo antes de producir

CTA:
"Puedo preparar una muestra o propuesta cerrada a partir de tu guion/brief."
'@
[IO.File]::WriteAllText((Join-Path $Offers 'FACTORIA-VIDEO-IA-OFFER.txt'),$videoOffer,[Text.UTF8Encoding]::new($false))

# Oferta 2: evaluacion/entrenamiento de IA como fuente de caja sin gasto de acceso.
$aiWork = @'
AI TRAINING / EVALUATION - RUTA COSTE 0
Objetivo: localizar y solicitar proyectos remotos compatibles con Espana.
Prioridad: evaluacion de respuestas, anotacion, data collection, prompting y tareas linguisticas.
Condiciones minimas:
- sin pago para acceder
- elegibilidad Espana o remoto
- tarifa/forma de pago visible o verificable antes de aceptar
- no enviar documentos sensibles fuera del flujo oficial de la plataforma
'@
[IO.File]::WriteAllText((Join-Path $Offers 'AI-TRAINING-COSTE0.txt'),$aiWork,[Text.UTF8Encoding]::new($false))

$opportunities = @(
    [ordered]@{
        id='WORKANA-AVATAR-VIDEO-2026-10-09'
        lane='FACTORIA'
        url='https://www.workana.com/es/job/editor-a-de-video-con-avatares-ia-para-contenido-en-redes-pago-por-video'
        state='TO_REVIEW_AND_APPLY'
        cost_gate='VERIFY_BEFORE_ACTION'
        note='Oferta publicada para edicion recurrente de videos con avatares IA; exige portfolio y respuestas concretas.'
    },
    [ordered]@{
        id='ONEFORMA-SPAIN-AI-PROJECTS'
        lane='AI_TRAINING'
        url='https://www.oneforma.com/projects/'
        state='TO_REVIEW_AND_APPLY'
        cost_gate='ZERO_ACCESS_COST_REQUIRED'
        note='Revisar proyectos abiertos compatibles con Spain y Remote.'
    }
)

foreach($o in $opportunities){
    Add-JsonLine -Path $Queue -Data @{
        id=$o.id; lane=$o.lane; url=$o.url; state=$o.state; cost_gate=$o.cost_gate; note=$o.note;
        payment_verified=$false; external_submission_verified=$false
    }
}

# Aplicacion preparada para Workana, sin inventar portfolio.
$proposal = @'
avatar natural

Puedo encargarme de la produccion y edicion vertical de videos con avatar IA para Instagram, TikTok y Shorts, incluyendo ritmo, subtitulos, limpieza de audio y adaptacion al estilo de referencia.

Puedo trabajar por lotes y documentar cada entrega para mantener consistencia entre piezas. Antes de enviar una candidatura definitiva, adjuntare unicamente ejemplos reales de trabajos que pueda acreditar y especificare las herramientas efectivamente disponibles.

Portfolio: PENDIENTE_DE_INSERTAR_ENLACES_REALES
Herramientas: PENDIENTE_DE_VERIFICAR_EN_EL_EQUIPO
Capacidad semanal: PENDIENTE_DE_CALCULAR_TRAS_CANARY
Plazo para lote de 20: PENDIENTE_DE_CALCULAR_TRAS_CANARY
'@
[IO.File]::WriteAllText((Join-Path $Offers 'WORKANA-PROPOSAL-DRAFT.txt'),$proposal,[Text.UTF8Encoding]::new($false))

# Diagnostico minimo del runtime OMNI-JIMMOSS.
$runtimeChecks = [ordered]@{}
$runtimeChecks['ledger_exists'] = Test-Path -LiteralPath $Ledger
$runtimeChecks['rag_exists'] = Test-Path -LiteralPath (Join-Path $Root 'rag\JARVIS-KNOWLEDGE-SOURCES.jsonl')
$runtimeChecks['tag_exists'] = Test-Path -LiteralPath (Join-Path $Root 'tag\knowledge-tags.jsonl')
$runtimeChecks['runtime_dir_exists'] = Test-Path -LiteralPath (Join-Path $Root 'OMNI-JIMMOSS-FULL')
$runtimeChecks['port_8766_listening'] = [bool](Get-NetTCPConnection -LocalPort 8766 -State Listen -ErrorAction SilentlyContinue)

$status = [ordered]@{
    generated_at=(Get-Date).ToString('o')
    mode='REVENUE_FIRST_COST0'
    priority_lanes=@('FACTORIA_VIDEO_AI','AI_TRAINING_EVALUATION')
    runtime=$runtimeChecks
    queue=$Queue
    offers=$Offers
    payment_verified=$false
    next_gate='VERIFY_REAL_PORTFOLIO_AND_SUBMIT_FIRST_APPLICATION'
}
$status | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Report -Encoding utf8

Add-JsonLine -Path $Ledger -Data @{
    event='REVENUE_SPRINT_PREPARED';
    source='START-OMNI-JIMMOSS-REVENUE-SPRINT-v1.ps1';
    payment_verified=$false;
    report=$Report
}

Write-Host ''
Write-Host 'OMNI-JIMMOSS FULL - REVENUE SPRINT v1' -ForegroundColor Cyan
Write-Host 'Coste de acceso: 0 EUR requerido' -ForegroundColor Green
Write-Host "Cola: $Queue"
Write-Host "Ofertas: $Offers"
Write-Host "Informe: $Report"
Write-Host ''
Write-Host 'SIGUIENTE ACCION:' -ForegroundColor Yellow
Write-Host '1) Verificar portfolio real de FactorIA.'
Write-Host '2) Enviar la primera candidatura real.'
Write-Host '3) Registrar SUBMITTED solo tras comprobar el envio.'
Write-Host '4) Registrar PAYMENT_VERIFIED solo tras comprobar el cobro.'
