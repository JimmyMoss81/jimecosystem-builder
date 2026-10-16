import json, os, re, time, uuid, subprocess, urllib.request, urllib.error
from pathlib import Path
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

ROOT = Path(r"C:\JIMEcosystem\JARVIS")
UI = ROOT / "OMNI-JIMMOSS-FULL" / "index.html"
MEMORY = ROOT / "memory" / "MI-SEGUNDO-YO-CONVERSATIONS.jsonl"
LEDGER = ROOT / "sincro" / "ledger.jsonl"
RAGDIR = ROOT / "rag"
OBSIDIAN = ROOT / "Obsidian" / "JIMEcosystem-Vault" / "JARVIS" / "Mi Segundo Yo"
SOL_INBOX = ROOT / "sol-worker" / "missions" / "inbox"
SOL_RESULTS = ROOT / "sol-worker" / "missions" / "results"
BUSINESS = ROOT / "business-hub" / "autonomy"
PORT_FILE = ROOT / "MiSegundoYo" / "runtime-port.txt"
LOG = ROOT / "logs" / "MI-SEGUNDO-YO-v42.log"

for p in [UI.parent, MEMORY.parent, LEDGER.parent, RAGDIR, OBSIDIAN, SOL_INBOX, SOL_RESULTS, BUSINESS, PORT_FILE.parent, LOG.parent]:
    p.mkdir(parents=True, exist_ok=True)
for p in [MEMORY, LEDGER]:
    if not p.exists(): p.write_text("", encoding="utf-8")

def append_jsonl(path, obj):
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=False) + "\n")

def log(msg):
    with LOG.open("a", encoding="utf-8") as f:
        f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")

def ledger(kind, state, detail, artifacts=None):
    append_jsonl(LEDGER, {
        "event_id": str(uuid.uuid4()), "timestamp": time.strftime('%Y-%m-%dT%H:%M:%S'),
        "source": "MI-SEGUNDO-YO-v4.2", "kind": kind, "state": state,
        "detail": detail, "artifacts": artifacts or [], "cost_eur": 0
    })

def persist(role, text):
    append_jsonl(MEMORY, {"timestamp": time.strftime('%Y-%m-%dT%H:%M:%S'), "role": role, "text": text})
    day = OBSIDIAN / f"{time.strftime('%Y-%m-%d')} Conversaciones.md"
    with day.open("a", encoding="utf-8") as f:
        f.write(f"\n### {time.strftime('%H:%M:%S')} {role}\n{text}\n")

def tail(path, n=12):
    try:
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
        return "\n".join(lines[-n:])
    except Exception:
        return ""

def search_knowledge(query):
    tokens = [t for t in re.findall(r"[\wáéíóúüñÁÉÍÓÚÜÑ-]+", query.lower()) if len(t) >= 4][:8]
    if not tokens: return ""
    hits = []
    targets = []
    try: targets += list(RAGDIR.rglob("*"))[:80]
    except Exception: pass
    try: targets += list((ROOT / "Obsidian" / "JIMEcosystem-Vault" / "JARVIS").rglob("*.md"))[:180]
    except Exception: pass
    for f in targets:
        if len(hits) >= 14: break
        if not f.is_file(): continue
        try:
            txt = f.read_text(encoding="utf-8", errors="ignore")
            low = txt.lower()
            if any(t in low for t in tokens):
                for line in txt.splitlines():
                    if any(t in line.lower() for t in tokens):
                        hits.append(f"[{f.name}] {line.strip()[:420]}")
                        if len(hits) >= 14: break
        except Exception:
            pass
    return "\n".join(hits)

def ollama_models():
    try:
        with urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=2) as r:
            data = json.loads(r.read().decode("utf-8"))
            return [m.get("name", "") for m in data.get("models", [])]
    except Exception:
        return []

def pick_model():
    models = ollama_models()
    preferred = ["qwen2.5:7b", "qwen2.5:3b", "llama3.2:3b", "llama3.2:latest", "tinyllama:latest"]
    for x in preferred:
        if x in models: return x
    for x in models:
        if not re.search(r"embed|nomic|moondream", x, re.I): return x
    return None

def ask_ollama(model, prompt):
    body = json.dumps({"model": model, "prompt": prompt, "stream": False,
                       "options": {"temperature": 0.2, "num_ctx": 4096, "num_predict": 900}}).encode("utf-8")
    req = urllib.request.Request("http://127.0.0.1:11434/api/generate", data=body,
                                 headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode("utf-8")).get("response", "").strip()

def queue_mission(action, payload, priority="high"):
    mid = "MSY-" + time.strftime('%Y%m%d-%H%M%S') + "-" + uuid.uuid4().hex[:6]
    mission = {"schema_version": 1, "mission_id": mid, "created_at": time.strftime('%Y-%m-%dT%H:%M:%S'),
               "owner": "MI-SEGUNDO-YO", "coordinator": "OMNI-JIMMOSS", "action": action,
               "priority": priority, "payload": payload}
    p = SOL_INBOX / f"{mid}.json"
    p.write_text(json.dumps(mission, ensure_ascii=False, indent=2), encoding="utf-8")
    ledger("mission_queued", "queued", f"{action} / {mid}", [str(p)])
    return mid

def revenue_suggestions():
    return [
        "Cerrar la Auditoría Express IA de 49 €: validar URL pública, cobro y entrega.",
        "Preparar 5 prospectos reales con problema observable y mensaje personalizado, sin spam.",
        "Convertir FactorÍA en un pack vendible de vídeo corto + voz + subtítulos + derivados multicanal.",
        "Revisar JimInCruise para una acción de captación cualificada a coste cero.",
        "Priorizar una oportunidad de trabajo o microtarea verificable que pueda completarse hoy."
    ]

def build_reply(message):
    persist("USER", message)
    knowledge = search_knowledge(message)
    mem = tail(MEMORY, 10)
    led = tail(LEDGER, 10)
    model = pick_model()
    mission = None
    lower = message.lower()
    if re.search(r"ingres|monetiz|venta|cliente|trabaj|dinero", lower):
        mission = queue_mission("business_hub_bootstrap", {"objective": message, "source": "OMNI-JIMMOSS-v4.2"}, "critical")
    elif re.search(r"repar|estado|stack|diagn", lower):
        mission = queue_mission("repair_stack_links", {"objective": message}, "high")
    elif re.search(r"sincron|obsidian|rag|memoria|conocimiento", lower):
        mission = queue_mission("sync_knowledge", {"objective": message}, "normal")

    if model:
        prompt = f"""Eres Mi Segundo Yo dentro de JIMEcosystem. Responde en español, con utilidad inmediata. No uses la frase 'el puente será el siguiente componente'. Usa el contexto real disponible. Si has creado una misión, dilo con su identificador. Prioriza coste cero y monetización verificable. No inventes ventas, saldos, conexiones ni capacidades. Acciones externas sensibles requieren aprobación humana.\n\nMENSAJE:\n{message}\n\nCONOCIMIENTO RECUPERADO:\n{knowledge}\n\nMEMORIA RECIENTE:\n{mem}\n\nLEDGER RECIENTE:\n{led}\n\nMISIÓN ENCOLADA:\n{mission or 'ninguna'}\n"""
        try:
            reply = ask_ollama(model, prompt)
            route = f"OLLAMA:{model}"
        except Exception as e:
            reply = f"He procesado tu orden localmente. Ollama estaba disponible pero falló al responder: {e}."
            route = f"OLLAMA_ERROR:{model}"
    else:
        route = "LOCAL_RULES"
        parts = ["He procesado tu orden con los componentes locales disponibles."]
        if knowledge: parts.append("He recuperado contexto de RAG/Obsidian relacionado con tu petición.")
        if mission: parts.append(f"He creado la misión {mission} para Sol-Worker.")
        else: parts.append("No hay ahora mismo un modelo Ollama de texto disponible; no voy a inventar una respuesta de IA.")
        if re.search(r"ingres|monetiz|venta|cliente|trabaj|dinero", lower):
            parts.append("Siguiente prioridad: " + revenue_suggestions()[0])
        reply = " ".join(parts)

    persist("ASSISTANT", reply)
    ledger("chat", "completed", route, [mission] if mission else [])
    return {"reply": reply, "route": route, "mission_id": mission}

class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload, ctype="application/json; charset=utf-8"):
        data = payload if isinstance(payload, bytes) else payload.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers(); self.wfile.write(data)
    def do_GET(self):
        if self.path == "/":
            if UI.exists(): self._send(200, UI.read_bytes(), "text/html; charset=utf-8")
            else: self._send(500, json.dumps({"error":"ui_missing"}))
        elif self.path == "/api/status":
            self._send(200, json.dumps({"status":"operational","local_model":pick_model(),"greeting":"Mi Segundo Yo v4.2 conectado a memoria persistente, RAG, Ledger, Obsidian y Sol-Worker."}, ensure_ascii=False))
        elif self.path == "/api/suggestions":
            self._send(200, json.dumps({"suggestions": revenue_suggestions()}, ensure_ascii=False))
        else:
            self._send(404, json.dumps({"error":"not_found"}))
    def do_POST(self):
        length = int(self.headers.get("Content-Length","0"))
        raw = self.rfile.read(length).decode("utf-8") if length else "{}"
        try: obj = json.loads(raw or "{}")
        except Exception: obj = {}
        if self.path == "/api/chat":
            msg = str(obj.get("message", "")).strip()
            if not msg: return self._send(400, json.dumps({"error":"empty_message"}))
            return self._send(200, json.dumps(build_reply(msg), ensure_ascii=False))
        if self.path == "/api/revenue":
            mid = queue_mission("business_hub_bootstrap", {"objective":"Generar progreso monetizable coste cero y preparar siguiente acción verificable","trigger":"UI"}, "critical")
            return self._send(200, json.dumps({"message":f"He creado la misión {mid} para Sol-Worker. Preparará trabajo local de monetización; publicaciones, pagos y envíos externos siguen sujetos a autorización."}, ensure_ascii=False))
        return self._send(404, json.dumps({"error":"not_found"}))
    def log_message(self, fmt, *args):
        return

def find_port():
    import socket
    for port in range(8777, 8800):
        s = socket.socket();
        try:
            s.bind(("127.0.0.1", port)); s.close(); return port
        except OSError:
            s.close()
    raise RuntimeError("No hay puerto libre entre 8777 y 8799")

if __name__ == "__main__":
    port = find_port()
    PORT_FILE.write_text(str(port), encoding="utf-8")
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    log(f"Runtime v4.2 iniciado en http://127.0.0.1:{port}/")
    ledger("runtime", "started", f"http://127.0.0.1:{port}/")
    server.serve_forever()
