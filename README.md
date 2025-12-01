# JIMEcosystem Builder 🚀

## Plataforma de Creación de Sitios Web para JIMEcosystem

**JIMEcosystem Builder** es un clon optimizado de Squarespace, diseñado específicamente para las necesidades del ecosistema JIM: viajes inteligentes, tiendas temáticas, automatización con IA, proyectos de solidaridad comunitaria y negocios digitales.

### 🎯 Características Principales

#### 🎨 Editor Visual Drag & Drop
- Editor WYSIWYG intuitivo similar a Squarespace
- Bloques personalizables para cada tipo de contenido
- Vista previa en tiempo real (desktop, tablet, mobile)
- Historial de cambios con deshacer/rehacer ilimitado

#### 🌐 Registro y Gestión de Dominios
- **Registro de dominios gratuito** para usuarios JIMEcosystem
- Integración con APIs de registradores (Namecheap, DNSimple, etc.)
- Gestión DNS automatizada
- Subdominios ilimitados

#### 📦 Plantillas Específicas JIMEcosystem

**1. Plantilla Viajes (JimInCruise)**
- Integración con JimInCruise.InCruises.com
- Calendarios de eventos y cruceros
- Sistema de reservas inteligente con IA
- Galería de destinos y experiencias

**2. Plantilla Tiendas (E-commerce)**
- Mascotas MARCOMANNY
- Confecciones JIM&LAU
- Menage MOSTAZA
- Vista personalizable (categorías, grid, lista, etc.)
- Carrito de compras integrado
- Pasarelas de pago (Stripe, PayPal)

**3. Plantilla Gana Dinero**
- Portal de trabajos digitales remunerados
- Categorías: Afiliación, Marketing, Trafficker, Funneler, Copywriter, Closer, Comercial Digital
- Filtros por skill, experiencia y modelo de ingresos
- Sistema de aplicación directa

**4. Plantilla Solidaridad / Comunitaria**
- Proyectos de impacto social
- Economía local y trueque digital
- Sistema de donaciones y voluntariado
- Transparencia de fondos

**5. Plantilla Automatización**
- Showcase de bots y agentes IA
- Plantillas Notion, Zapier/Make
- Biblioteca de prompts
- Tutoriales y casos de uso

---

## 🛠️ Stack Tecnológico

### Frontend
```
- React 18+ con TypeScript
- Next.js 14 (App Router)
- TailwindCSS + Shadcn/ui
- DraftJS / Lexical (editor visual)
- React DnD (drag and drop)
```

### Backend
```
- Node.js + Express / Fastify
- PostgreSQL (base de datos principal)
- Redis (caché y sesiones)
- AWS S3 (almacenamiento de medios)
- Cloudflare Workers (CDN y edge computing)
```

### APIs de Dominios
```
- Namecheap API
- DNSimple REST API
- Cloudflare DNS API
- Route53 (AWS)
```

### Despliegue
```
- Docker + Docker Compose
- Vercel (frontend)
- AWS/DigitalOcean (backend)
- GitHub Actions (CI/CD)
```

---

## 📐 Arquitectura del Sistema

### Componentes Principales

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND (Next.js)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Editor Visual│  │ Plantillas   │  │ Preview      │  │
│  │ (DraftJS)    │  │ System       │  │ Engine       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────────┐
│               API REST (Node.js + Express)               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │Sites API │  │Domains   │  │Templates │  │Media    │ │
│  │          │  │API       │  │API       │  │API      │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────────┐
│                    SERVICIOS BASE                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │PostgreSQL│  │Redis     │  │AWS S3    │  │Domain   │ │
│  │(Data)    │  │(Cache)   │  │(Files)   │  │Registrar│ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Flujo de Trabajo

1. **Usuario accede al Builder** → Autenticación JWT
2. **Selecciona plantilla** → Viajes, Tiendas, Gana Dinero, Solidaridad, Automatización
3. **Editor visual** → Drag & drop bloques, personalización CSS
4. **Registro de dominio** → API Namecheap/DNSimple → DNS automático
5. **Preview & Publish** → Genera sitio estático → CDN Cloudflare
6. **Hosting automático** → Despliegue en Vercel/AWS

---

## 🚀 Instalación y Configuración

### Requisitos Previos

```bash
Node.js >= 18.x
PostgreSQL >= 14.x
Redis >= 7.x
Docker (opcional)
```

### 1. Clonar Repositorio

```bash
git clone https://github.com/JimmyMoss81/jimecosystem-builder.git
cd jimecosystem-builder
```

### 2. Instalar Dependencias

```bash
# Frontend
cd frontend
npm install

# Backend
cd ../backend
npm install
```

### 3. Configurar Variables de Entorno

Crea archivos `.env` en frontend y backend:

**backend/.env**
```env
DATABASE_URL=postgresql://user:pass@localhost:5432/jimbuilder
REDIS_URL=redis://localhost:6379
JWT_SECRET=tu-secreto-seguro

# APIs de Dominios
NAMECHEAP_API_KEY=tu-api-key
NAMECHEAP_API_USER=tu-username
DNSIMPLE_TOKEN=tu-token

# AWS S3
AWS_ACCESS_KEY_ID=tu-key
AWS_SECRET_ACCESS_KEY=tu-secret
AWS_S3_BUCKET=jimbuilder-media
AWS_REGION=us-east-1
```

**frontend/.env.local**
```env
NEXT_PUBLIC_API_URL=http://localhost:4000/api
NEXT_PUBLIC_CDN_URL=https://cdn.jimecosystem.com
```

### 4. Inicializar Base de Datos

```bash
cd backend
npm run db:migrate
npm run db:seed
```

### 5. Ejecutar en Desarrollo

```bash
# Terminal 1 - Backend
cd backend
npm run dev

# Terminal 2 - Frontend
cd frontend
npm run dev
```

Accede a:
- Frontend: http://localhost:3000
- Backend API: http://localhost:4000

---

## 📦 Despliegue en Producción

### Opción 1: Docker Compose

```bash
docker-compose up -d
```

### Opción 2: Manual

```bash
# Build Frontend
cd frontend
npm run build

# Deploy a Vercel
vercel --prod

# Build Backend
cd backend
npm run build

# Deploy a AWS/DigitalOcean
node dist/server.js
```

---

## 📚 Documentación Completa

- [Arquitectura Técnica](./docs/architecture.md)
- [API Reference](./docs/api-reference.md)
- [Editor Visual - Guía](./docs/visual-editor.md)
- [Sistema de Plantillas](./docs/templates.md)
- - [🤖 Guía de Creación de Bots](./BOT-CREATION-GUIDE.md)
- [Integración Dominios](./docs/domain-api.md)
- [Despliegue Automático](./docs/deployment.md)

---

## 📝 Roadmap

### Fase 1: MVP (Q1 2026)
- [x] Repositorio y documentación base
- [ ] Editor visual básico
- [ ] Sistema de plantillas (5 plantillas iniciales)
- [ ] Registro de dominios (Namecheap)
- [ ] Hosting automático

### Fase 2: JIMEcosystem Integration (Q2 2026)
- [ ] Integración JimInCruise.InCruises.com
- [ ] Tiendas: MARCOMANNY, JIM&LAU, MOSTAZA
- [ ] Portal "Gana Dinero" con filtros avanzados
- [ ] Módulo Solidaridad Comunitaria

### Fase 3: Automatización & IA (Q3 2026)
- [ ] Asistente IA para diseño
- [ ] Generación de contenido con GPT-4
- [ ] Optimización SEO automática
- [ ] A/B testing integrado

### Fase 4: Marketplace (Q4 2026)
- [ ] Marketplace de plantillas
- [ ] Plugins y extensiones
- [ ] API pública para desarrolladores
- [ ] Sistema de afiliados

---

## 🤝 Contribuir

Este proyecto es parte del ecosistema JIM. Si quieres contribuir:

1. Fork el repositorio
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'Add: nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request

---

## 📝 Licencia

MIT License - JIMEcosystem 2025

---

## 👥 Equipo

- **Jimmy Moss** - Fundador y Arquitecto Principal
- **Frank C.** - Infraestructura y Automatización
- **Michael H.** - Desarrollo Full Stack

---

## 📧 Contacto

- Web: [JIMEcosystem.com](https://jimecosystem.com)
- Email: contacto@jimecosystem.com
- GitHub: [@JimmyMoss81](https://github.com/JimmyMoss81)

---

**⭐ Si este proyecto te resulta útil, dale una estrella!**
